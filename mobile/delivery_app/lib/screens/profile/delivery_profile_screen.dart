import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../auth/login_screen.dart';

class DeliveryProfileScreen extends StatelessWidget {
  static const String routeName = '/delivery-profile';

  const DeliveryProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            onPressed: () {
              // Edit profile
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            
            const SizedBox(height: 24),
            
            // Quick Stats
            _buildQuickStats(),
            
            const SizedBox(height: 24),
            
            // Menu Options
            _buildMenuSection(context),
            
            const SizedBox(height: 32),
            
            // Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child: authProvider.user?.avatar != null
                      ? Image.network(
                          authProvider.user!.avatar!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.user?.name ?? 'Delivery Driver',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.user?.email ?? 'driver@example.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer<DeliveryProvider>(
      builder: (context, deliveryProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Today',
                value: '${deliveryProvider.todayDeliveries}',
                subtitle: 'Deliveries',
                icon: Icons.local_shipping,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Earnings',
                value: '${AppConstants.currencySymbol}${deliveryProvider.todayEarnings.toStringAsFixed(0)}',
                subtitle: 'Today',
                icon: Icons.account_balance_wallet,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Rating',
                value: '4.8',
                subtitle: 'Stars',
                icon: Icons.star,
                color: AppColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        _MenuItem(
          icon: Icons.history,
          title: 'Delivery History',
          subtitle: 'View all past deliveries',
          onTap: () {
            // Navigate to delivery history
          },
        ),
        
        _MenuItem(
          icon: Icons.account_balance_wallet,
          title: 'Earnings',
          subtitle: 'View earnings and payouts',
          onTap: () {
            // Navigate to earnings screen
          },
        ),
        
        _MenuItem(
          icon: Icons.star_rate,
          title: 'Ratings & Reviews',
          subtitle: 'Customer feedback',
          onTap: () {
            // Navigate to ratings screen
          },
        ),
        
        _MenuItem(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage notifications',
          onTap: () {
            // Navigate to notification settings
          },
        ),
        
        _MenuItem(
          icon: Icons.support_agent,
          title: 'Help & Support',
          subtitle: 'Contact support team',
          onTap: () {
            // Navigate to support screen
          },
        ),
        
        _MenuItem(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences',
          onTap: () {
            // Navigate to settings
          },
        ),
        
        _MenuItem(
          icon: Icons.info,
          title: 'About',
          subtitle: 'App version and info',
          onTap: () {
            _showAboutDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
              
              // Clear data
              deliveryProvider.clear();
              await authProvider.logout();
              
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.local_shipping,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'Taiga Delivery App helps delivery personnel manage their orders efficiently and provide excellent service to customers.',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}