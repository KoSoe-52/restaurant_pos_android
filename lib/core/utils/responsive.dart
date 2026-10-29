import 'package:flutter/material.dart';

/// Breakpoints
/// phone  : width < 600
/// tablet : 600 <= width < 900
/// desktop: width >= 900  (future-proof, treated as tablet here)
class AppResponsive {
  AppResponsive._();

  // ── Breakpoints ───────────────────────────────────────────────────────
  static const double _tabletBreak  = 600;
  static const double _desktopBreak = 900;

  static bool isPhone(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width < _tabletBreak;
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width >= _tabletBreak;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width >= _desktopBreak;

  // ── Value helpers ─────────────────────────────────────────────────────
  /// Returns [phone] on phones, [tablet] on tablets/desktops.
  static T value<T>(
    BuildContext ctx, {
    required T phone,
    required T tablet,
    T? desktop,
  }) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w >= _desktopBreak) return desktop ?? tablet;
    if (w >= _tabletBreak)  return tablet;
    return phone;
  }

  // ── Content max-width ────────────────────────────────────────────────
  /// Constrains content width on large screens (tablet/desktop).
  static double contentMaxWidth(BuildContext ctx) =>
      isTablet(ctx) ? 720 : double.infinity;

  /// Horizontal padding that grows on wider screens.
  static EdgeInsets screenPadding(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w >= _desktopBreak) return const EdgeInsets.symmetric(horizontal: 48);
    if (w >= _tabletBreak)  return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  // ── Grid ─────────────────────────────────────────────────────────────
  /// Max cross-axis extent for product / table grid tiles.
  static double tableCardExtent(BuildContext ctx) =>
      value(ctx, phone: 140.0, tablet: 160.0);
  static double productCardExtent(BuildContext ctx) =>
      value(ctx, phone: 150.0, tablet: 170.0);

  /// Cross-axis spacing for grids.
  static double gridSpacing(BuildContext ctx) =>
      value(ctx, phone: 10.0, tablet: 14.0);

  // ── Typography scale ─────────────────────────────────────────────────
  static double titleLg(BuildContext ctx)  => value(ctx, phone: 18.0, tablet: 22.0);
  static double titleMd(BuildContext ctx)  => value(ctx, phone: 15.0, tablet: 17.0);
  static double titleSm(BuildContext ctx)  => value(ctx, phone: 13.0, tablet: 15.0);
  static double bodyMd(BuildContext ctx)   => value(ctx, phone: 12.0, tablet: 14.0);
  static double bodySm(BuildContext ctx)   => value(ctx, phone: 11.0, tablet: 13.0);
  static double labelSm(BuildContext ctx)  => value(ctx, phone: 10.0, tablet: 12.0);

  // ── Icon sizes ────────────────────────────────────────────────────────
  static double iconMd(BuildContext ctx)   => value(ctx, phone: 20.0, tablet: 24.0);
  static double iconSm(BuildContext ctx)   => value(ctx, phone: 16.0, tablet: 18.0);

  // ── Card / padding ────────────────────────────────────────────────────
  static double cardRadius(BuildContext ctx) => value(ctx, phone: 14.0, tablet: 16.0);
  static EdgeInsets cardPadding(BuildContext ctx) =>
      value(ctx, phone: const EdgeInsets.all(14), tablet: const EdgeInsets.all(20));

  // ── Bottom nav / rail ─────────────────────────────────────────────────
  /// True when app should show NavigationRail instead of BottomNavigationBar.
  static bool useNavRail(BuildContext ctx) => isTablet(ctx);
}

/// Convenience extension so you can write `context.isTablet`, etc.
extension ResponsiveContext on BuildContext {
  bool get isPhone   => AppResponsive.isPhone(this);
  bool get isTablet  => AppResponsive.isTablet(this);
  bool get isDesktop => AppResponsive.isDesktop(this);
}
