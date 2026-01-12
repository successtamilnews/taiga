import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../products/product_management_screen.dart';
import '../orders/seller_orders_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/seller_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ProductManagementScreen(),
    const SellerOrdersScreen(),
    const AnalyticsScreen(),
    const SellerProfileScreen(),
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
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    await Future.wait([
      inventoryProvider.loadProducts(),
      orderProvider.loadOrders(),
    ]);
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
                // Header
                _buildHeader(),
                
                const SizedBox(height: 20),
                
                // Quick Stats
                _buildQuickStats(),
                
                const SizedBox(height: 24),
                
                // Recent Orders
                _buildRecentOrdersSection(),
                
                const SizedBox(height: 24),
                
                // Top Products
                _buildTopProductsSection(),
                
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              authProvider.user?.name ?? 'Seller',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Store Active',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer2<InventoryProvider, OrderProvider>(
      builder: (context, inventoryProvider, orderProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Products',
                value: '${inventoryProvider.products.length}',
                icon: Icons.inventory_2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Pending Orders',
                value: '${orderProvider.pendingOrders.length}',
                icon: Icons.pending,
                color: AppColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(SellerOrdersScreen.routeName);
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
        Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (orderProvider.orders.isEmpty) {
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
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No orders yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: orderProvider.orders
                  .take(3)
                  .map((order) => _OrderItem(order: order))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ProductManagementScreen.routeName);
              },
              child: const Text(
                'Manage',
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<InventoryProvider>(
          builder: (context, inventoryProvider, child) {
            if (inventoryProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (inventoryProvider.products.isEmpty) {
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
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products added',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: inventoryProvider.products.length,
                itemBuilder: (context, index) {
                  final product = inventoryProvider.products[index];
                  return _ProductItem(product: product);
                },
              ),
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _ActionCard(
              title: 'Add Product',
              icon: Icons.add_box,
              color: AppColors.primary,
              onTap: () {
                // Navigate to add product screen
              },
            ),
            _ActionCard(
              title: 'View Sales',
              icon: Icons.trending_up,
              color: AppColors.success,
              onTap: () {
                Navigator.of(context).pushNamed(AnalyticsScreen.routeName);
              },
            ),
            _ActionCard(
              title: 'Manage Orders',
              icon: Icons.list_alt,
              color: AppColors.warning,
              onTap: () {
                Navigator.of(context).pushNamed(SellerOrdersScreen.routeName);
              },
            ),
            _ActionCard(
              title: 'Settings',
              icon: Icons.settings,
              color: AppColors.textSecondary,
              onTap: () {
                Navigator.of(context).pushNamed(SellerProfileScreen.routeName);
              },
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
              fontSize: 24,
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

class _OrderItem extends StatelessWidget {
  final dynamic order; // Replace with proper Order model

  const _OrderItem({
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
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning,
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
                  'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}1,250',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final dynamic product; // Replace with proper Product model

  const _ProductItem({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  'Product Name',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppConstants.currencySymbol}299',
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
        color: AppColors.cardBackground,
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
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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