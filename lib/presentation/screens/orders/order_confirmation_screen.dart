import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/table_provider.dart';
import '../home_screen.dart';
import 'order_detail_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    // Refresh tables in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().refreshTables();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AuthProvider>().settings.currencySymbol;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Placed'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Go to Home',
            onPressed: _goHome,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Success animation
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const Text(
                    'Order Placed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.order.orderNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Print job status card
            _buildPrintStatusCard(),
            const SizedBox(height: 16),
            // Order summary card
            _buildOrderSummaryCard(currency),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderId: widget.order.id),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View Order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _goHome,
                    icon: const Icon(Icons.table_restaurant_outlined),
                    label: const Text('Back to Tables'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintStatusCard() {
    final jobs = widget.order.printJobs;
    if (jobs.isEmpty) {
      return _StatusCard(
        icon: Icons.print_outlined,
        iconColor: AppColors.info,
        title: 'Order Sent to Kitchen',
        subtitle: 'Print jobs are being processed',
        bgColor: AppColors.info.withValues(alpha: 0.05),
        borderColor: AppColors.info.withValues(alpha: 0.3),
      );
    }

    final hasFailed = jobs.any((j) => j.hasFailed);

    return Container(
      decoration: BoxDecoration(
        color: hasFailed
            ? AppColors.warning.withValues(alpha: 0.05)
            : AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFailed
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  hasFailed ? Icons.warning_amber : Icons.print,
                  color: hasFailed ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasFailed ? 'Some Printers Failed' : 'Sent to Printers',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasFailed ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...jobs.map(
            (job) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _printerIcon(job.printer),
                    size: 18,
                    color: job.hasFailed ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 10),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _jobStatusColor(job.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      job.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _jobStatusColor(job.status),
                      ),
                    ),
                  ),
                  if (job.hasFailed) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _retryJob(job.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'You can retry failed print jobs from Order Details',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(String currency) {
    final order = widget.order;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (order.table != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.table!.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...order.activeItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontSize: 13),
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
                      ],
                    ),
                  ),
                  Text(
                    Formatters.currency(item.subtotal, symbol: currency),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  Formatters.currency(order.total, symbol: currency),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryJob(int jobId) async {
    final success = await context.read<OrderProvider>().retryPrintJob(jobId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Print job queued for retry' : 'Failed to retry print job',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
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

  Color _jobStatusColor(String status) {
    switch (status) {
      case 'sent':
        return AppColors.success;
      case 'queued':
        return AppColors.info;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color borderColor;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}
