import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_provider.dart';
import '../../models/order.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../components/loading_overlay.dart';
import 'order_details_screen.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  static const String routeName = '/delivery-orders';

  const DeliveryOrdersScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await Provider.of<DeliveryProvider>(context, listen: false).loadAssignedOrders();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Orders',
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
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Available'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _ActiveOrdersTab(),
            _AvailableOrdersTab(),
            _CompletedOrdersTab(),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, deliveryProvider, child) {
        if (deliveryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (deliveryProvider.activeOrders.isEmpty) {
          return _EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'No Active Deliveries',
            message: 'You currently have no active delivery orders.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => deliveryProvider.loadAssignedOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveryProvider.activeOrders.length,
            itemBuilder: (context, index) {
              final order = deliveryProvider.activeOrders[index];
              return _OrderCard(
                order: order,
                isActive: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _AvailableOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Available Orders',
      message: 'Turn on availability to receive new delivery orders.',
      actionText: 'Go Online',
      onAction: () {
        // Toggle online status
      },
    );
  }
}

class _CompletedOrdersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, deliveryProvider, child) {
        if (deliveryProvider.recentOrders.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Completed Deliveries',
            message: 'Your completed delivery orders will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => deliveryProvider.loadAssignedOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveryProvider.recentOrders.length,
            itemBuilder: (context, index) {
              final order = deliveryProvider.recentOrders[index];
              return _OrderCard(
                order: order,
                isActive: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isActive;
  final VoidCallback onTap;

  const _OrderCard({
    Key? key,
    required this.order,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? AppColors.primary.withOpacity(0.3) 
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.customer?.name ?? 'Customer',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${order.deliveryAddress?.street ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatOrderTime(order.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
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
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(order.status),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppConstants.currencySymbol}${order.total?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '${order.items?.length ?? 0} items',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          text: _getActionText(order.status),
                          color: AppColors.primary,
                          onPressed: () => _handleAction(context, order),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          text: 'Call Customer',
                          color: AppColors.info,
                          onPressed: () => _callCustomer(context, order),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppColors.warning;
      case 'picked_up':
        return AppColors.info;
      case 'in_transit':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Assigned';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _getActionText(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Pick Up';
      case 'picked_up':
        return 'Start Delivery';
      case 'in_transit':
        return 'Complete';
      default:
        return 'View Details';
    }
  }

  String _formatOrderTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleAction(BuildContext context, Order order) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    
    switch (order.status.toLowerCase()) {
      case 'assigned':
        deliveryProvider.pickUpOrder(order.id);
        break;
      case 'picked_up':
        deliveryProvider.startDelivery(order.id);
        break;
      case 'in_transit':
        deliveryProvider.completeDelivery(order.id);
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
          ),
        );
        break;
    }
  }

  void _callCustomer(BuildContext context, Order order) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling customer...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    Key? key,
    required this.text,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(160, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}