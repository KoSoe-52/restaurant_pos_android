import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
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
      menu.resetFilters();
      menu.clearCart();
      menu.loadCategories();
      menu.loadProducts();
      // Sync the text controller with the provider reset so the search box
      // visually clears when re-entering the screen.
      _searchCtrl.clear();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu     = context.watch<MenuProvider>();
    final settings = context.watch<AuthProvider>().settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, menu, settings.currencySymbol),
      body: Column(
        children: [
          _buildSearchBar(context, menu),
          _buildCategoryChips(context, menu),
          const Divider(height: 1),
          Expanded(
            child: _buildProductGrid(context, menu, settings.currencySymbol),
          ),
        ],
      ),
      bottomNavigationBar: menu.hasCartItems
          ? _buildCartBar(context, menu, settings.currencySymbol)
          : null,
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    MenuProvider menu,
    String currency,
  ) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.table.name,
            style: TextStyle(
              fontSize: AppResponsive.titleMd(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            widget.existingOrderId != null
                ? 'Add to existing order'
                : 'New order',
            style: TextStyle(
              fontSize: AppResponsive.bodySm(context),
              fontWeight: FontWeight.w400,
            ),
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

  Widget _buildSearchBar(BuildContext context, MenuProvider menu) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.value(context, phone: 12.0, tablet: 16.0),
        12,
        AppResponsive.value(context, phone: 12.0, tablet: 16.0),
        8,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => v.isEmpty ? menu.clearSearch() : menu.setSearch(v),
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

  Widget _buildCategoryChips(BuildContext context, MenuProvider menu) {
    if (menu.isLoadingCategories) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final cats = [null, ...menu.categories];

    return SizedBox(
      height: AppResponsive.value(context, phone: 44.0, tablet: 52.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.value(context, phone: 12.0, tablet: 16.0),
          vertical: AppResponsive.value(context, phone: 4.0, tablet: 6.0),
        ),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat        = cats[i];
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
                fontSize: AppResponsive.bodyMd(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(
    BuildContext context,
    MenuProvider menu,
    String currency,
  ) {
    if (menu.isLoadingProducts && menu.products.isEmpty) {
      return const ShimmerGrid(count: 8, crossAxisCount: 3);
    }
    if (menu.error != null && menu.products.isEmpty) {
      return AppError(
        message: menu.error!,
        onRetry: () => menu.loadProducts(refresh: true),
      );
    }

    final spacing = AppResponsive.gridSpacing(context);
    final extent  = AppResponsive.productCardExtent(context);
    final hPad    = AppResponsive.value(context, phone: 12.0, tablet: 16.0);

    return Stack(
      children: [
        if (menu.products.isEmpty && !menu.isLoadingProducts)
          const AppEmpty(
            message: 'No products found',
            icon: Icons.fastfood_outlined,
          )
        else
          GridView.builder(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 100),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: extent,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              // Fixed row height — image (w/1.2) + name(2 lines) + price +
              // button fits within this on every density/width.
              mainAxisExtent: AppResponsive.value(
                context,
                phone: 208.0,
                tablet: 235.0,
              ),
            ),
            itemCount: menu.products.length,
            itemBuilder: (_, i) => _ProductCard(
              product: menu.products[i],
              currency: currency,
              quantity: menu.getQuantityInCart(menu.products[i].id),
              onAdd: () => menu.addToCart(menu.products[i]),
              onRemove: () => menu.removeFromCart(menu.products[i].id),
            ),
          ),
        // Loading overlay when switching category / search
        if (menu.isLoadingProducts)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCartBar(
    BuildContext context,
    MenuProvider menu,
    String currency,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${menu.cartItemCount} items',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppResponsive.bodyMd(context),
              ),
            ),
          ),
          const Spacer(),
          Text(
            Formatters.currency(menu.cartTotal, symbol: currency),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppResponsive.value(context, phone: 18.0, tablet: 20.0),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.cartBackground,
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.value(context, phone: 20.0, tablet: 28.0),
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _openCart(context, menu, currency),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Cart',
                  style: TextStyle(
                    fontSize: AppResponsive.bodyMd(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
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

// ─── Product Card ─────────────────────────────────────────────────────────────

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
    final r      = AppResponsive.cardRadius(context);

    return GestureDetector(
      onTap: onAdd,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
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
            // Product image — fixed fraction of card height via AspectRatio
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.fastfood,
                            color: AppColors.textHint,
                          ),
                        ),
                        errorWidget: (_, _, _) =>
                            _placeholder(product.printerTarget),
                      )
                    : _placeholder(product.printerTarget),
              ),
            ),
            // Info area — no Spacer; use MainAxisAlignment.spaceBetween
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppResponsive.value(context, phone: 7.0, tablet: 10.0),
                  AppResponsive.value(context, phone: 5.0, tablet: 7.0),
                  AppResponsive.value(context, phone: 7.0, tablet: 10.0),
                  AppResponsive.value(context, phone: 5.0, tablet: 7.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: AppResponsive.bodySm(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.currency(
                            product.sellPrice,
                            symbol: currency,
                          ),
                          style: TextStyle(
                            fontSize: AppResponsive.bodySm(context),
                            fontWeight: FontWeight.w700,
                            color: inCart
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (inCart)
                          _QuantityControl(
                            quantity: quantity,
                            onAdd: onAdd,
                            onRemove: onRemove,
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: AppResponsive.value(
                              context,
                              phone: 24.0,
                              tablet: 28.0,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: onAdd,
                              child: Icon(
                                Icons.add,
                                size: AppResponsive.value(
                                  context,
                                  phone: 16.0,
                                  tablet: 18.0,
                                ),
                              ),
                            ),
                          ),
                      ],
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

  Widget _placeholder(String printerTarget) {
    final IconData icon;
    final Color color;
    switch (printerTarget) {
      case 'beer':
        icon = Icons.sports_bar; color = Colors.amber.shade300;
      case 'kitchen':
        icon = Icons.restaurant; color = Colors.orange.shade200;
      default:
        icon = Icons.fastfood; color = Colors.grey.shade200;
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
    final btnSize = AppResponsive.value(context, phone: 24.0, tablet: 28.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.remove, size: 14, color: AppColors.primary),
          ),
        ),
        Text(
          '$quantity',
          style: TextStyle(
            fontSize: AppResponsive.bodyMd(context),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
