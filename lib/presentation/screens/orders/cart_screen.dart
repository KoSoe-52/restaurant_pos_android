import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/models/table_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/menu_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  final RestaurantTable table;
  final int? existingOrderId;

  const CartScreen({
    super.key,
    required this.table,
    this.existingOrderId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final settings = context.watch<AuthProvider>().settings;
    final orderProv = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.table.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.existingOrderId != null
                  ? 'Adding to existing order'
                  : 'New order',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (menu.hasCartItems)
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Clear Cart',
                  message:
                      'Remove all items from the cart?',
                  confirmLabel: 'Clear',
                  confirmColor: AppColors.error,
                  icon: Icons.delete_outline,
                );
                if (confirm == true && mounted) {
                  menu.clearCart();
                  nav.pop();
                }
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: menu.cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : _buildCartList(menu, settings.currencySymbol),
          ),
          if (menu.hasCartItems)
            _buildOrderSummary(menu, settings, orderProv),
        ],
      ),
    );
  }

  Widget _buildCartList(MenuProvider menu, String currency) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      children: [
        // Cart items
        ...menu.cartItems.map(
          (item) => _CartItemTile(
            item: item,
            currency: currency,
            onAdd: () => menu.addToCart(item.product),
            onRemove: () => menu.removeFromCart(item.product.id),
            onDelete: () => menu.removeItemCompletely(item.product.id),
            onNoteChanged: (note) =>
                menu.updateItemNote(item.product.id, note),
          ),
        ),
        const SizedBox(height: 16),
        // Order note
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Order Note (optional)',
              hintText: 'Special instructions, allergies...',
              prefixIcon: Icon(Icons.note_alt_outlined),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOrderSummary(
    MenuProvider menu,
    RestaurantSettings settings,
    OrderProvider orderProv,
  ) {
    final taxRate = settings.taxRate;
    final subtotal = menu.cartTotal;
    final tax = (subtotal * taxRate / 100).round();
    final total = subtotal + tax;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  Formatters.currency(subtotal, symbol: settings.currencySymbol),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (taxRate > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (${taxRate.toStringAsFixed(0)}%)',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    Formatters.currency(tax, symbol: settings.currencySymbol),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  Formatters.currency(total, symbol: settings.currencySymbol),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: orderProv.isSubmitting ? null : _submitOrder,
                child: orderProv.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.existingOrderId != null
                                ? 'Add to Order'
                                : 'Place Order',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    final menu = context.read<MenuProvider>();
    final orderProv = context.read<OrderProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final items = menu.getCartAsOrderItems();
    final note = _noteCtrl.text.trim();

    Order? result;
    if (widget.existingOrderId != null) {
      result = await orderProv.addItems(widget.existingOrderId!, items);
    } else {
      result = await orderProv.createOrder(
        tableId: widget.table.id,
        note: note.isNotEmpty ? note : null,
        items: items,
      );
    }

    if (!mounted) return;

    if (result != null) {
      menu.clearCart();
      // Navigate to confirmation, clearing the menu+cart stack
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: result!),
        ),
        (route) => route.isFirst,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(orderProv.error ?? 'Failed to place order'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CartItemTile extends StatefulWidget {
  final CartItem item;
  final String currency;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;
  final ValueChanged<String> onNoteChanged;

  const _CartItemTile({
    required this.item,
    required this.currency,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
    required this.onNoteChanged,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  bool _showNoteField = false;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.item.note);
    _showNoteField = widget.item.note.isNotEmpty;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                // Product icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.item.product.printerTarget == 'beer'
                        ? Icons.sports_bar
                        : Icons.restaurant,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Formatters.currency(
                          widget.item.product.sellPrice,
                          symbol: widget.currency,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quantity controls
                Row(
                  children: [
                    _iconBtn(Icons.remove, widget.onRemove, Colors.grey.shade200, AppColors.textSecondary),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${widget.item.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _iconBtn(Icons.add, widget.onAdd, AppColors.primary, Colors.white),
                  ],
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(
                        widget.item.subtotal,
                        symbol: widget.currency,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                            () => _showNoteField = !_showNoteField,
                          ),
                          child: Icon(
                            Icons.note_alt_outlined,
                            size: 16,
                            color: _showNoteField
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_showNoteField)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: TextField(
                controller: _noteCtrl,
                onChanged: widget.onNoteChanged,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Item note (e.g. no ice)...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    VoidCallback onTap,
    Color bg,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}
