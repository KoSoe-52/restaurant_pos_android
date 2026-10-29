import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/providers/auth_provider.dart';
import 'tables/table_grid_screen.dart';
import 'orders/my_orders_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    TableGridScreen(),
    MyOrdersScreen(),
    ProfileScreen(),
  ];

  void _onDestinationSelected(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final useRail = AppResponsive.useNavRail(context);

    final destinations = [
      _NavDestination(
        icon: Icons.table_restaurant_outlined,
        activeIcon: Icons.table_restaurant,
        label: 'Tables',
      ),
      _NavDestination(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'My Orders',
      ),
      _NavDestination(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: user?.name.split(' ').first ?? 'Profile',
      ),
    ];

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textSecondary,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    // Phone: BottomNavigationBar
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onDestinationSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: destinations
              .map(
                (d) => BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  activeIcon: Icon(d.activeIcon),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
