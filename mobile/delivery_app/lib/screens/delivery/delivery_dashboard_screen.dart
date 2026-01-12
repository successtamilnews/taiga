import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../orders/delivery_orders_screen.dart';
import '../map/map_screen.dart';
import '../profile/delivery_profile_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  static const String routeName = '/delivery-dashboard';

  const DeliveryDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DeliveryHomePage(),
    const DeliveryOrdersScreen(),
    const MapScreen(),
    const DeliveryProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({Key? key}) : super(key: key);

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    await deliveryProvider.loadAssignedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Online Status
                _buildHeader(),
                
                const SizedBox(height: 20),
                
                // Today's Stats
                _buildTodayStats(),
                
                const SizedBox(height: 24),
                
                // Active Deliveries
                _buildActiveDeliveriesSection(),
                
                const SizedBox(height: 24),
                
                // Recent Deliveries
                _buildRecentDeliveriesSection(),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${authProvider.user?.name ?? 'Driver'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Ready for deliveries today?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: _isOnline,
                  onChanged: (value) {
                    setState(() {
                      _isOnline = value;
                    });
                    // TODO: Update online status
                  },
                  activeColor: AppColors.success,
                ),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayStats() {
    return Consumer<DeliveryProvider>(
      builder: (context, deliveryProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Today\\'s Deliveries',
                value: '${deliveryProvider.todayDeliveries}',
                icon: Icons.local_shipping,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Earnings',
                value: '${AppConstants.currencySymbol}${deliveryProvider.todayEarnings}',
                icon: Icons.attach_money,
                color: AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveDeliveriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Deliveries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(DeliveryOrdersScreen.routeName);
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<DeliveryProvider>(
          builder: (context, deliveryProvider, child) {
            if (deliveryProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (deliveryProvider.activeOrders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No active deliveries',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Turn on availability to receive orders',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: deliveryProvider.activeOrders
                  .map((order) => _ActiveDeliveryItem(order: order))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentDeliveriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Deliveries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<DeliveryProvider>(
          builder: (context, deliveryProvider, child) {
            if (deliveryProvider.recentOrders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No recent deliveries',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: deliveryProvider.recentOrders
                  .take(3)
                  .map((order) => _RecentDeliveryItem(order: order))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'View Map',
                icon: Icons.map,
                color: AppColors.primary,
                onTap: () {
                  Navigator.of(context).pushNamed(MapScreen.routeName);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'Earnings',
                icon: Icons.account_balance_wallet,
                color: AppColors.success,
                onTap: () {
                  // Navigate to earnings screen
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Support',
                icon: Icons.support_agent,
                color: AppColors.info,
                onTap: () {
                  // Navigate to support screen
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: 'History',
                icon: Icons.history,
                color: AppColors.textSecondary,
                onTap: () {
                  // Navigate to delivery history
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDeliveryItem extends StatelessWidget {
  final dynamic order; // Replace with proper Order model

  const _ActiveDeliveryItem({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #12345',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer: John Doe',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Distance: 2.5 km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'In Transit',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppConstants.currencySymbol}50',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to order details
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Start delivery
                    },
                    icon: const Icon(Icons.navigation, size: 16),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 32),
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
}

class _RecentDeliveryItem extends StatelessWidget {
  final dynamic order; // Replace with proper Order model

  const _RecentDeliveryItem({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.check,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #12344',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Delivered • 2 hours ago',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}45',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}