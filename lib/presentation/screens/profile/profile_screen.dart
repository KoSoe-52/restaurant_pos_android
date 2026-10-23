import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final settings = auth.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card
            _buildProfileCard(user, settings),
            const SizedBox(height: 16),
            // Restaurant info
            _buildRestaurantCard(settings),
            const SizedBox(height: 16),
            // App info
            _buildAppInfoCard(),
            const SizedBox(height: 24),
            // Logout button
            _buildLogoutButton(context, auth),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(WaiterUser? user, RestaurantSettings settings) {
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'W',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(RestaurantSettings settings) {
    return _Card(
      title: 'Restaurant Info',
      icon: Icons.store_outlined,
      children: [
        _InfoRow(
          label: 'Name',
          value: settings.restaurantName,
          icon: Icons.restaurant,
        ),
        if (settings.restaurantAddress != null)
          _InfoRow(
            label: 'Address',
            value: settings.restaurantAddress!,
            icon: Icons.location_on_outlined,
          ),
        if (settings.restaurantPhone != null)
          _InfoRow(
            label: 'Phone',
            value: settings.restaurantPhone!,
            icon: Icons.phone_outlined,
          ),
        _InfoRow(
          label: 'Currency',
          value: settings.currencySymbol,
          icon: Icons.attach_money_outlined,
        ),
        if (settings.taxRate > 0)
          _InfoRow(
            label: 'Tax Rate',
            value: '${settings.taxRate.toStringAsFixed(0)}%',
            icon: Icons.percent_outlined,
          ),
      ],
    );
  }

  Widget _buildAppInfoCard() {
    return _Card(
      title: 'App Info',
      icon: Icons.info_outline,
      children: [
        _InfoRow(
          label: 'Version',
          value: '1.0.0',
          icon: Icons.new_releases_outlined,
        ),
        _InfoRow(
          label: 'Platform',
          value: 'Flutter',
          icon: Icons.flutter_dash,
        ),
        _InfoRow(
          label: 'Role',
          value: 'Waiter App',
          icon: Icons.work_outline,
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: auth.isLoading
            ? null
            : () => _logout(context, auth),
        icon: auth.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : const Icon(Icons.logout_outlined),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      confirmColor: AppColors.error,
      icon: Icons.logout_outlined,
    );
    if (confirm != true || !context.mounted) return;

    await auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
