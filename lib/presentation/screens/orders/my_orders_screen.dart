import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/order_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/status_badge.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  String? _selectedStatus; // null = all
  final _scrollCtrl = ScrollController();

  static const _filters = [
    _Filter(label: 'All', status: null),
    _Filter(label: 'Open', status: 'open'),
    _Filter(label: 'Served', status: 'served'),
    _Filter(label: 'Paid', status: 'paid'),
    _Filter(label: 'Voided', status: 'voided'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadOrders({bool refresh = false}) {
    context.read<OrderProvider>().loadOrders(
          status: _selectedStatus,
          myOrders: true,
          refresh: refresh,
        );
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final provider = context.read<OrderProvider>();
      if (!provider.isLoading && provider.hasMore) {
        _loadOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final orderProv = context.watch<OrderProvider>();
    final currency = context.watch<AuthProvider>().settings.currencySymbol;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOrders(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(child: _buildContent(orderProv, currency)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _filters.length,
          itemBuilder: (_, i) {
            final f = _filters[i];
            final isSelected = _selectedStatus == f.status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedStatus = f.status);
                  _loadOrders(refresh: true);
                },
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade300,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(OrderProvider provider, String currency) {
    if (provider.isLoading && provider.orders.isEmpty) {
      return const AppLoading(message: 'Loading orders...');
    }
    if (provider.error != null && provider.orders.isEmpty) {
      return AppError(
        message: provider.error!,
        onRetry: () => _loadOrders(refresh: true),
      );
    }
    if (provider.orders.isEmpty) {
      return AppEmpty(
        message: 'No orders found',
        subtitle: _selectedStatus != null
            ? 'No $_selectedStatus orders at the moment'
            : 'Your orders will appear here',
        icon: Icons.receipt_long_outlined,
        onAction: () => _loadOrders(refresh: true),
        actionLabel: 'Refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadOrders(refresh: true),
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppResponsive.contentMaxWidth(context),
          ),
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: EdgeInsets.all(
              AppResponsive.value(context, phone: 12.0, tablet: 20.0),
            ),
        itemCount: provider.orders.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == provider.orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return _OrderCard(
            order: provider.orders[i],
            currency: currency,
            onTap: () => _openDetail(provider.orders[i]),
          );
        },
          ),
        ),
      ),
    );
  }

  void _openDetail(Order order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        )
        .then((_) => _loadOrders(refresh: true));
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final String currency;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFailedPrint = order.hasFailedPrintJobs;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFailedPrint
                ? AppColors.warning.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.orderNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (hasFailedPrint) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.print_disabled,
                                size: 14,
                                color: AppColors.warning,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.table != null
                              ? order.table!.name
                              : (order.customerName != null
                                  ? 'Takeaway - ${order.customerName}'
                                  : 'Takeaway'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.orderStatus(order.status, order.statusLabel),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.fastfood_outlined,
                    label: '${order.displayItemCount} items',
                  ),
                  const SizedBox(width: 10),
                  _InfoChip(
                    icon: Icons.access_time_outlined,
                    label: Formatters.timeAgo(order.orderedAt),
                  ),
                  const Spacer(),
                  Text(
                    Formatters.currency(order.total, symbol: currency),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              // Item preview
              if (order.activeItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  order.activeItems
                      .take(3)
                      .map((i) => '${i.quantity}x ${i.productName}')
                      .join(', ') +
                      (order.activeItems.length > 3
                          ? '...'
                          : ''),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Filter {
  final String label;
  final String? status;

  const _Filter({required this.label, required this.status});
}
