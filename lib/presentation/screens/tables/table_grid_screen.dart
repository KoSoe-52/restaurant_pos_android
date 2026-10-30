import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
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
              style: TextStyle(
                fontSize: AppResponsive.titleMd(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Select a Table',
              style: TextStyle(
                fontSize: AppResponsive.bodySm(context),
                fontWeight: FontWeight.w400,
              ),
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
          _buildLegend(context),
          Expanded(
            child: _buildContent(context, tableProvider, settings.currencySymbol),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.value(context, phone: 16.0, tablet: 24.0),
        vertical: 10,
      ),
      child: Row(
        children: [
          _legendDot(context, AppColors.available, 'Available'),
          const SizedBox(width: 16),
          _legendDot(context, AppColors.occupied, 'Occupied'),
          const SizedBox(width: 16),
          _legendDot(context, AppColors.reserved, 'Reserved'),
          const Spacer(),
          Consumer<TableProvider>(
            builder: (_, p, _) => Text(
              '${p.tables.length} tables',
              style: TextStyle(
                fontSize: AppResponsive.bodySm(context),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
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
          style: TextStyle(
            fontSize: AppResponsive.bodySm(context),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    TableProvider provider,
    String currency,
  ) {
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
      child: _buildGroupedTables(context, provider.tables, currency),
    );
  }

  Widget _buildGroupedTables(
    BuildContext context,
    List<RestaurantTable> tables,
    String currency,
  ) {
    final Map<String, List<RestaurantTable>> grouped = {};
    for (final t in tables) {
      grouped.putIfAbsent(t.location ?? 'Main', () => []).add(t);
    }
    final locations = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: 24,
        left: AppResponsive.value(context, phone: 0.0, tablet: 8.0),
        right: AppResponsive.value(context, phone: 0.0, tablet: 8.0),
      ),
      itemCount: locations.length,
      itemBuilder: (_, i) => _buildLocationSection(
        context,
        locations[i],
        grouped[locations[i]]!,
        currency,
      ),
    );
  }

  Widget _buildLocationSection(
    BuildContext context,
    String location,
    List<RestaurantTable> tables,
    String currency,
  ) {
    final spacing = AppResponsive.gridSpacing(context);
    final extent  = AppResponsive.tableCardExtent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppResponsive.value(context, phone: 16.0, tablet: 20.0),
            16, 16, 8,
          ),
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
                style: TextStyle(
                  fontSize: AppResponsive.titleSm(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${tables.length})',
                style: TextStyle(
                  fontSize: AppResponsive.bodyMd(context),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.value(context, phone: 12.0, tablet: 16.0),
          ),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: extent,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.9,
          ),
          itemCount: tables.length,
          itemBuilder: (_, i) =>
              _TableCard(table: tables[i], currency: currency),
        ),
      ],
    );
  }
}

// ─── Table Card ──────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final RestaurantTable table;
  final String currency;

  const _TableCard({required this.table, required this.currency});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.tableStatusColor(table.status);
    final hasOrder    = table.activeOrder != null;
    final r           = AppResponsive.cardRadius(context);

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
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
        padding: EdgeInsets.all(
          AppResponsive.value(context, phone: 8.0, tablet: 12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status dot + capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 9,
                  height: 9,
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
                      size: AppResponsive.value(context, phone: 11.0, tablet: 13.0),
                      color: AppColors.textSecondary,
                    ),
                    Text(
                      '${table.capacity}',
                      style: TextStyle(
                        fontSize: AppResponsive.labelSm(context),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Table icon
            Center(
              child: Icon(
                Icons.table_restaurant,
                size: AppResponsive.value(context, phone: 28.0, tablet: 34.0),
                color: statusColor.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            // Table name
            Center(
              child: Text(
                table.name,
                style: TextStyle(
                  fontSize: AppResponsive.titleSm(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            // Status badge / order info
            Center(
              child: hasOrder
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.currency(
                            table.activeOrder!.total,
                            symbol: currency,
                          ),
                          style: TextStyle(
                            fontSize: AppResponsive.labelSm(context),
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          '${table.activeOrder!.itemCount} items',
                          style: TextStyle(
                            fontSize: AppResponsive.labelSm(context),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        table.statusLabel,
                        style: TextStyle(
                          fontSize: AppResponsive.labelSm(context),
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (table.activeOrder != null) {
      _showTableOptions(context);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MenuScreen(table: table)),
      );
    }
  }

  void _showTableOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _TableOptionsSheet(
        table: table,
        order: table.activeOrder!,
      ),
    );
  }
}

// ─── Table Options Sheet ─────────────────────────────────────────────────────

class _TableOptionsSheet extends StatelessWidget {
  final RestaurantTable table;
  final TableActiveOrder order;

  const _TableOptionsSheet({required this.table, required this.order});

  @override
  Widget build(BuildContext context) {
    final currency = context.read<AuthProvider>().settings.currencySymbol;
    final isOpen   = order.status == 'open';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
          // Transfer table — only visible when order status is 'open'
          if (isOpen) ...[
            const SizedBox(height: 10),
            _OptionTile(
              icon: Icons.compare_arrows_rounded,
              label: 'Transfer Table',
              subtitle: 'Move order to another table',
              color: const Color(0xFF7C3AED), // violet-700
              onTap: () {
                Navigator.of(context).pop();
                _showTransferTableSheet(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showTransferTableSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TransferTableSheet(
        sourceTable: table,
        orderId: order.id,
      ),
    );
  }
}

// ─── Transfer Table Sheet ────────────────────────────────────────────────────

class _TransferTableSheet extends StatefulWidget {
  final RestaurantTable sourceTable;
  final int orderId;

  const _TransferTableSheet({
    required this.sourceTable,
    required this.orderId,
  });

  @override
  State<_TransferTableSheet> createState() => _TransferTableSheetState();
}

class _TransferTableSheetState extends State<_TransferTableSheet> {
  RestaurantTable? _selectedTable;
  bool _isConfirmStep = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final tableProvider = context.watch<TableProvider>();

    // Filter: not source, not disabled, no active order
    final availableTargets = tableProvider.tables
        .where((t) =>
            t.id != widget.sourceTable.id &&
            t.status != 'disabled' &&
            t.activeOrder == null)
        .toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          MediaQuery.paddingOf(context).bottom,
        ),
        child: _isConfirmStep
            ? _buildConfirmStep(context)
            : _buildSelectStep(context, availableTargets),
      ),
    );
  }

  Widget _buildSelectStep(
    BuildContext context,
    List<RestaurantTable> availableTargets,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transfer Table',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'From: ${widget.sourceTable.name}  ·  Select destination',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Table grid
        Padding(
          padding: const EdgeInsets.all(16),
          child: availableTargets.isEmpty
              ? _buildEmptyTargets(context)
              : _buildTargetGrid(context, availableTargets),
        ),
        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedTable == null
                      ? null
                      : () => setState(() => _isConfirmStep = true),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTargets(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No available tables',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All other tables are occupied or disabled.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetGrid(
    BuildContext context,
    List<RestaurantTable> targets,
  ) {
    final Map<String, List<RestaurantTable>> grouped = {};
    for (final t in targets) {
      grouped.putIfAbsent(t.location ?? 'Main', () => []).add(t);
    }
    final locations = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final loc in locations) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              loc,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grouped[loc]!.map((t) => _buildTableChip(t)).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTableChip(RestaurantTable t) {
    final isSelected = _selectedTable?.id == t.id;
    final statusColor = AppTheme.tableStatusColor(t.status);

    return GestureDetector(
      onTap: () => setState(() => _selectedTable = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : statusColor.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Color(0xFF7C3AED),
                ),
              ),
            Icon(
              Icons.table_restaurant,
              size: 14,
              color: isSelected ? const Color(0xFF7C3AED) : statusColor,
            ),
            const SizedBox(width: 6),
            Text(
              t.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF7C3AED) : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmStep(BuildContext context) {
    final target = _selectedTable!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirm Transfer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // From → To visual
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _tableInfoCard(
                      label: 'From',
                      tableName: widget.sourceTable.name,
                      statusColor: AppColors.occupied,
                      statusLabel: 'Occupied',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF7C3AED),
                        size: 18,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _tableInfoCard(
                      label: 'To',
                      tableName: target.name,
                      statusColor: AppTheme.tableStatusColor(target.status),
                      statusLabel: target.statusLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All orders from ${widget.sourceTable.name} will be moved to ${target.name}. This action cannot be undone.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isConfirmStep = false),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _doTransfer(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.compare_arrows_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Transfer'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableInfoCard({
    required String label,
    required String tableName,
    required Color statusColor,
    required String statusLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Icon(Icons.table_restaurant, size: 28, color: statusColor),
          const SizedBox(height: 6),
          Text(
            tableName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doTransfer(BuildContext context) async {
    if (_selectedTable == null) return;

    setState(() => _isLoading = true);

    final tableProvider = context.read<TableProvider>();
    final error = await tableProvider.transferTable(
      widget.orderId,
      _selectedTable!.id,
    );

    if (!context.mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.of(context).pop(); // close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order transferred from ${widget.sourceTable.name} to ${_selectedTable!.name} successfully.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── Option Tile ─────────────────────────────────────────────────────────────

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
                      fontSize: AppResponsive.titleSm(context),
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
