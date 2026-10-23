import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/table_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/menu_provider.dart';
import '../../widgets/common/app_loading.dart';
import '../orders/cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final RestaurantTable table;
  final int? existingOrderId;

  const MenuScreen({
    super.key,
    required this.table,
    this.existingOrderId,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menu = context.read<MenuProvider>();
      menu.clearCart();
      menu.loadCategories();
      menu.loadProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final settings = context.watch<AuthProvider>().settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(menu, settings.currencySymbol),
      body: Column(
        children: [
          _buildSearchBar(menu),
          _buildCategoryChips(menu),
          const Divider(height: 1),
          Expanded(child: _buildProductGrid(menu, settings.currencySymbol)),
        ],
      ),
      bottomNavigationBar: menu.hasCartItems
          ? _buildCartBar(menu, settings.currencySymbol)
          : null,
    );
  }

  AppBar _buildAppBar(MenuProvider menu, String currency) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.table.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            widget.existingOrderId != null
                ? 'Add to existing order'
                : 'New order',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        if (menu.hasCartItems)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _openCart(context, menu, currency),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${menu.cartItemCount}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSearchBar(MenuProvider menu) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          if (v.isEmpty) {
            menu.clearSearch();
          } else {
            menu.setSearch(v);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search menu...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    menu.clearSearch();
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildCategoryChips(MenuProvider menu) {
    if (menu.isLoadingCategories) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final cats = [null, ...menu.categories.map((c) => c)];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final isSelected = cat == null
              ? menu.selectedCategoryId == null
              : menu.selectedCategoryId == cat.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat?.name ?? 'All'),
              selected: isSelected,
              onSelected: (_) => menu.selectCategory(cat?.id),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(MenuProvider menu, String currency) {
    if (menu.isLoadingProducts && menu.products.isEmpty) {
      return const ShimmerGrid(count: 8, crossAxisCount: 3);
    }
    if (menu.error != null && menu.products.isEmpty) {
      return AppError(
        message: menu.error!,
        onRetry: () => menu.loadProducts(refresh: true),
      );
    }
    if (menu.products.isEmpty) {
      return const AppEmpty(
        message: 'No products found',
        icon: Icons.fastfood_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: menu.products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: menu.products[i],
        currency: currency,
        quantity: menu.getQuantityInCart(menu.products[i].id),
        onAdd: () => menu.addToCart(menu.products[i]),
        onRemove: () => menu.removeFromCart(menu.products[i].id),
      ),
    );
  }

  Widget _buildCartBar(MenuProvider menu, String currency) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.cartBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${menu.cartItemCount} items',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Spacer(),
            Text(
              Formatters.currency(menu.cartTotal, symbol: currency),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.cartBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openCart(context, menu, currency),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Cart',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCart(BuildContext context, MenuProvider menu, String currency) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(
          table: widget.table,
          existingOrderId: widget.existingOrderId,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String currency;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product,
    required this.currency,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;

    return GestureDetector(
      onTap: onAdd,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inCart
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: inCart
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.fastfood,
                            color: AppColors.textHint,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _placeholderImage(product.printerTarget),
                      )
                    : _placeholderImage(product.printerTarget),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      Formatters.currency(product.sellPrice, symbol: currency),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: inCart ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Quantity controls
                    if (inCart)
                      _QuantityControl(
                        quantity: quantity,
                        onAdd: onAdd,
                        onRemove: onRemove,
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 26,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: onAdd,
                          child: const Icon(Icons.add, size: 18),
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

  Widget _placeholderImage(String printerTarget) {
    IconData icon;
    Color color;
    switch (printerTarget) {
      case 'beer':
        icon = Icons.sports_bar;
        color = Colors.amber.shade300;
        break;
      case 'kitchen':
        icon = Icons.restaurant;
        color = Colors.orange.shade200;
        break;
      default:
        icon = Icons.fastfood;
        color = Colors.grey.shade200;
    }
    return Container(
      color: color.withValues(alpha: 0.3),
      child: Icon(icon, color: color, size: 36),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.remove,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ),
        Text(
          '$quantity',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.add,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
