import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/table_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/table_provider.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/status_badge.dart';
import '../menu/menu_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final currency = context.watch<AuthProvider>().settings.currencySymbol;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          orderProv.currentOrder?.orderNumber ?? 'Order Details',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                orderProv.loadOrderDetail(widget.orderId),
          ),
        ],
      ),
      body: _buildBody(orderProv, currency),
    );
  }

  Widget _buildBody(OrderProvider provider, String currency) {
    if (provider.isLoading && provider.currentOrder == null) {
      return const AppLoading(message: 'Loading order...');
    }
    if (provider.error != null && provider.currentOrder == null) {
      return AppError(
        message: provider.error!,
        onRetry: () => provider.loadOrderDetail(widget.orderId),
      );
    }
    final order = provider.currentOrder;
    if (order == null) return const AppLoading();

    return Stack(
      children: [
        _buildContent(order, currency, provider),
        if (provider.isSubmitting)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(Order order, String currency, OrderProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(order, currency),
          const SizedBox(height: 16),
          if (order.hasFailedPrintJobs)
            _buildPrintFailureWarning(order, provider),
          if (order.hasFailedPrintJobs) const SizedBox(height: 16),
          _buildItemsList(order, currency, provider),
          const SizedBox(height: 16),
          _buildTotalsCard(order, currency),
          const SizedBox(height: 16),
          if (order.printJobs.isNotEmpty) _buildPrintJobsCard(order, provider),
          if (order.printJobs.isNotEmpty) const SizedBox(height: 16),
          _buildActionsCard(order, provider, currency),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(Order order, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.dateTime(order.orderedAt),
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Info row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (order.table != null)
                _InfoItem(
                  icon: Icons.table_restaurant_outlined,
                  label: 'Table',
                  value: order.table!.name,
                ),
              if (order.waiter != null)
                _InfoItem(
                  icon: Icons.person_outline,
                  label: 'Waiter',
                  value: order.waiter!.name,
                ),
              if (order.customerName != null)
                _InfoItem(
                  icon: Icons.person_pin_outlined,
                  label: 'Customer',
                  value: order.customerName!,
                ),
              if (order.servedAt != null)
                _InfoItem(
                  icon: Icons.check_circle_outline,
                  label: 'Served At',
                  value: Formatters.time(order.servedAt!),
                ),
            ],
          ),
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.note!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrintFailureWarning(Order order, OrderProvider provider) {
    final failedJobs = order.printJobs.where((j) => j.hasFailed).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.print_disabled, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${failedJobs.length} printer(s) failed',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                const Text(
                  'Tap retry to resend to printers',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _retryAllFailed(failedJobs, provider),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
            ),
            child: const Text('Retry All'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(Order order, String currency, OrderProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items (${order.items.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (order.canAddItems)
                  TextButton.icon(
                    onPressed: () => _addMoreItems(order),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Items'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...order.items.map(
            (item) => _OrderItemTile(
              item: item,
              currency: currency,
              canVoid: order.canVoid && !item.isVoided,
              onVoid: () => _voidItem(order, item, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(Order order, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _TotalRow(
            label: 'Subtotal',
            value: Formatters.currency(order.subtotal, symbol: currency),
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 4),
            _TotalRow(
              label: 'Discount',
              value: '-${Formatters.currency(order.discount, symbol: currency)}',
              valueColor: AppColors.success,
            ),
          ],
          if (order.tax > 0) ...[
            const SizedBox(height: 4),
            _TotalRow(
              label: 'Tax',
              value: Formatters.currency(order.tax, symbol: currency),
            ),
          ],
          const Divider(height: 20),
          _TotalRow(
            label: 'Total',
            value: Formatters.currency(order.total, symbol: currency),
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            valueStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintJobsCard(Order order, OrderProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Print Jobs',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          ...order.printJobs.map(
            (job) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    _printerIcon(job.printer),
                    size: 20,
                    color: job.hasFailed
                        ? AppColors.error
                        : AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.printerTarget(job.printer),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (job.hasFailed && job.error != null)
                          Text(
                            job.error!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                            ),
                            maxLines: 2,
                          ),
                        Text(
                          'Attempts: ${job.attempts} • ${Formatters.timeAgo(job.createdAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _jobStatusBadge(job.status),
                  if (job.hasFailed) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      tooltip: 'Retry',
                      onPressed: () => _retryJob(job.id, provider),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    Order order,
    OrderProvider provider,
    String currency,
  ) {
    if (!order.canServe && !order.canVoid) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (order.canServe) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _serveOrder(order, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Served'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (order.canVoid) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _voidOrder(order, provider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Void Entire Order'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _jobStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'sent':
        color = AppColors.success;
        break;
      case 'queued':
        color = AppColors.info;
        break;
      case 'failed':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _serveOrder(Order order, OrderProvider provider) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Mark as Served',
      message:
          'Mark ${order.orderNumber} as served? This means all food has been delivered.',
      confirmLabel: 'Served',
      confirmColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
    if (confirm != true || !mounted) return;

    final ok = await provider.serveOrder(order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Order marked as served' : provider.error ?? 'Failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      context.read<TableProvider>().refreshTables();
    }
  }

  Future<void> _voidOrder(Order order, OrderProvider provider) async {
    final reason = await VoidReasonDialog.show(
      context,
      title: 'Void Order',
      hint: 'Why are you voiding this order?',
    );
    if (reason == null || !mounted) return;

    final ok = await provider.voidOrder(order.id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Order voided' : provider.error ?? 'Failed to void'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      context.read<TableProvider>().refreshTables();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _voidItem(
    Order order,
    OrderItem item,
    OrderProvider provider,
  ) async {
    final reason = await VoidReasonDialog.show(
      context,
      title: 'Void Item',
      hint: 'Why are you voiding "${item.productName}"?',
    );
    if (reason == null || !mounted) return;

    final updatedOrder =
        await provider.voidItem(order.id, item.id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedOrder != null ? 'Item voided' : provider.error ?? 'Failed',
        ),
        backgroundColor:
            updatedOrder != null ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _retryJob(int jobId, OrderProvider provider) async {
    final ok = await provider.retryPrintJob(jobId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Print job queued' : 'Failed to retry'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) provider.loadOrderDetail(widget.orderId);
  }

  Future<void> _retryAllFailed(
    List<PrintJob> failedJobs,
    OrderProvider provider,
  ) async {
    for (final job in failedJobs) {
      await provider.retryPrintJob(job.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All failed jobs queued for retry'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    provider.loadOrderDetail(widget.orderId);
  }

  void _addMoreItems(Order order) {
    // Find table from provider
    final tables = context.read<TableProvider>().tables;
    final table = order.table != null
        ? tables.firstWhere(
            (t) => t.id == order.table!.id,
            orElse: () => RestaurantTable(
              id: order.table!.id,
              name: order.table!.name,
              capacity: 4,
              status: 'occupied',
              statusLabel: 'Occupied',
            ),
          )
        : RestaurantTable(
            id: 0,
            name: 'Takeaway',
            capacity: 1,
            status: 'occupied',
            statusLabel: 'Occupied',
          );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          table: table,
          existingOrderId: order.id,
        ),
      ),
    );
  }

  IconData _printerIcon(String printer) {
    switch (printer) {
      case 'beer':
        return Icons.sports_bar;
      case 'kitchen':
        return Icons.kitchen;
      case 'cashier':
        return Icons.point_of_sale;
      default:
        return Icons.print;
    }
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final String currency;
  final bool canVoid;
  final VoidCallback onVoid;

  const _OrderItemTile({
    required this.item,
    required this.currency,
    required this.canVoid,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    final isVoided = item.isVoided;

    return GestureDetector(
      onLongPress: canVoid ? onVoid : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isVoided
              ? AppColors.textHint.withValues(alpha: 0.05)
              : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            // Quantity badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isVoided
                    ? AppColors.textHint.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isVoided ? AppColors.textHint : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isVoided
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      decoration:
                          isVoided ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.note != null && item.note!.isNotEmpty)
                    Text(
                      item.note!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (isVoided && item.voidReason != null)
                    Text(
                      'Void: ${item.voidReason}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(item.subtotal, symbol: currency),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isVoided
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    decoration:
                        isVoided ? TextDecoration.lineThrough : null,
                  ),
                ),
                StatusBadge.itemStatus(item.status, item.statusLabel),
              ],
            ),
            if (canVoid) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onVoid,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ??
              const TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
