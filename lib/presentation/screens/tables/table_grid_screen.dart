import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/table_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/table_provider.dart';
import '../../widgets/common/app_loading.dart';
import '../menu/menu_screen.dart';
import '../orders/order_detail_screen.dart';

class TableGridScreen extends StatefulWidget {
  const TableGridScreen({super.key});

  @override
  State<TableGridScreen> createState() => _TableGridScreenState();
}

class _TableGridScreenState extends State<TableGridScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TableProvider>();
      provider.loadTables();
      provider.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    context.read<TableProvider>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableProvider = context.watch<TableProvider>();
    final settings = context.watch<AuthProvider>().settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.restaurantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Select a Table',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tables',
            onPressed: () => tableProvider.loadTables(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLegend(),
          Expanded(child: _buildContent(tableProvider, settings.currencySymbol)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _legendDot(AppColors.available, 'Available'),
          const SizedBox(width: 16),
          _legendDot(AppColors.occupied, 'Occupied'),
          const SizedBox(width: 16),
          _legendDot(AppColors.reserved, 'Reserved'),
          const Spacer(),
          Consumer<TableProvider>(
            builder: (_, p, child) => Text(
              '${p.tables.length} tables',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildContent(TableProvider provider, String currency) {
    if (provider.isLoading && provider.tables.isEmpty) {
      return const AppLoading(message: 'Loading tables...');
    }
    if (provider.error != null && provider.tables.isEmpty) {
      return AppError(
        message: provider.error!,
        onRetry: provider.loadTables,
      );
    }
    if (provider.tables.isEmpty) {
      return const AppEmpty(
        message: 'No tables found',
        icon: Icons.table_restaurant_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadTables,
      color: AppColors.primary,
      child: _buildGroupedTables(provider.tables, currency),
    );
  }

  Widget _buildGroupedTables(List<RestaurantTable> tables, String currency) {
    // Group by location
    final Map<String, List<RestaurantTable>> grouped = {};
    for (final t in tables) {
      final loc = t.location ?? 'Main';
      grouped.putIfAbsent(loc, () => []).add(t);
    }

    final locations = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: locations.length,
      itemBuilder: (_, i) {
        final loc = locations[i];
        final locTables = grouped[loc]!;
        return _buildLocationSection(loc, locTables, currency);
      },
    );
  }

  Widget _buildLocationSection(
    String location,
    List<RestaurantTable> tables,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${tables.length})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: tables.length,
          itemBuilder: (_, i) =>
              _TableCard(table: tables[i], currency: currency),
        ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  final RestaurantTable table;
  final String currency;

  const _TableCard({required this.table, required this.currency});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.tableStatusColor(table.status);
    final hasOrder = table.activeOrder != null;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator + capacity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        '${table.capacity}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Table icon
              Center(
                child: Icon(
                  Icons.table_restaurant,
                  size: 32,
                  color: statusColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              // Table name
              Center(
                child: Text(
                  table.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Status or order info
              Center(
                child: hasOrder
                    ? Column(
                        children: [
                          Text(
                            Formatters.currency(
                              table.activeOrder!.total,
                              symbol: currency,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            '${table.activeOrder!.itemCount} items',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          table.statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (table.activeOrder != null) {
      // Navigate to order detail or add items
      _showTableOptions(context);
    } else {
      // Navigate to menu to create new order
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MenuScreen(table: table),
        ),
      );
    }
  }

  void _showTableOptions(BuildContext context) {
    final order = table.activeOrder!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TableOptionsSheet(table: table, order: order),
    );
  }
}

class _TableOptionsSheet extends StatelessWidget {
  final RestaurantTable table;
  final TableActiveOrder order;

  const _TableOptionsSheet({required this.table, required this.order});

  @override
  Widget build(BuildContext context) {
    final currency =
        context.read<AuthProvider>().settings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.occupied.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.table_restaurant,
                  color: AppColors.occupied,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(order.total, symbol: currency),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${order.itemCount} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // View Order
          _OptionTile(
            icon: Icons.receipt_long_outlined,
            label: 'View Order Details',
            subtitle: 'See all items and actions',
            color: AppColors.info,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderId: order.id),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Add more items
          _OptionTile(
            icon: Icons.add_circle_outline,
            label: 'Add More Items',
            subtitle: 'Add items to existing order',
            color: AppColors.success,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MenuScreen(
                    table: table,
                    existingOrderId: order.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
