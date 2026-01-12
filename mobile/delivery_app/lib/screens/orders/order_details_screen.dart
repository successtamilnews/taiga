import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_provider.dart';
import '../../models/order.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../components/loading_overlay.dart';

class OrderDetailsScreen extends StatefulWidget {
  static const String routeName = '/order-details';

  final Order order;

  const OrderDetailsScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${widget.order.id}',
          style: const TextStyle(
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
              // Call customer
              _callCustomer();
            },
            icon: const Icon(Icons.phone),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Status Card
              _buildStatusCard(),
              
              const SizedBox(height: 20),
              
              // Customer Information
              _buildCustomerInfo(),
              
              const SizedBox(height: 20),
              
              // Delivery Address
              _buildDeliveryAddress(),
              
              const SizedBox(height: 20),
              
              // Order Items
              _buildOrderItems(),
              
              const SizedBox(height: 20),
              
              // Order Summary
              _buildOrderSummary(),
              
              const SizedBox(height: 20),
              
              // Delivery Notes
              if (_canAddNotes()) _buildDeliveryNotes(),
              
              const SizedBox(height: 100), // Space for bottom actions
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(),
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildCustomerInfo() {
    return _SectionCard(
      title: 'Customer Information',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person,
            label: 'Name',
            value: widget.order.customer?.name ?? 'N/A',
          ),
          _InfoRow(
            icon: Icons.phone,
            label: 'Phone',
            value: widget.order.customer?.phone ?? 'N/A',
            isAction: true,
            onTap: _callCustomer,
          ),
          _InfoRow(
            icon: Icons.email,
            label: 'Email',
            value: widget.order.customer?.email ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    final address = widget.order.deliveryAddress;
    return _SectionCard(
      title: 'Delivery Address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.location_on,
            label: 'Address',
            value: address?.street ?? 'N/A',
          ),
          if (address?.city != null) 
            _InfoRow(
              icon: Icons.location_city,
              label: 'City',
              value: address!.city!,
            ),
          if (address?.state != null)
            _InfoRow(
              icon: Icons.map,
              label: 'State',
              value: address!.state!,
            ),
          if (address?.zipCode != null)
            _InfoRow(
              icon: Icons.markunread_mailbox,
              label: 'ZIP Code',
              value: address!.zipCode!,
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Open navigation
                _openNavigation();
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return _SectionCard(
      title: 'Order Items',
      child: Column(
        children: [
          ...?widget.order.items?.map((item) => _OrderItemTile(item: item)),
          if (widget.order.items?.isEmpty ?? true)
            const Text(
              'No items found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return _SectionCard(
      title: 'Order Summary',
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal',
            value: '${AppConstants.currencySymbol}${widget.order.subtotal?.toStringAsFixed(2) ?? '0.00'}',
          ),
          _SummaryRow(
            label: 'Delivery Fee',
            value: '${AppConstants.currencySymbol}${widget.order.deliveryFee?.toStringAsFixed(2) ?? '0.00'}',
          ),
          if ((widget.order.tax ?? 0) > 0)
            _SummaryRow(
              label: 'Tax',
              value: '${AppConstants.currencySymbol}${widget.order.tax?.toStringAsFixed(2) ?? '0.00'}',
            ),
          if ((widget.order.discount ?? 0) > 0)
            _SummaryRow(
              label: 'Discount',
              value: '-${AppConstants.currencySymbol}${widget.order.discount?.toStringAsFixed(2) ?? '0.00'}',
              isDiscount: true,
            ),
          const Divider(),
          _SummaryRow(
            label: 'Total',
            value: '${AppConstants.currencySymbol}${widget.order.total?.toStringAsFixed(2) ?? '0.00'}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNotes() {
    return _SectionCard(
      title: 'Delivery Notes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add delivery notes (optional)...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Text(
            'Notes will be visible to the customer',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (widget.order.status == 'delivered' || widget.order.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Consumer<DeliveryProvider>(
        builder: (context, deliveryProvider, child) {
          return Row(
            children: [
              if (_canReportIssue()) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reportIssue(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Report Issue'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: deliveryProvider.isUpdatingStatus 
                      ? null 
                      : () => _handlePrimaryAction(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getPrimaryActionColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                  ),
                  child: deliveryProvider.isUpdatingStatus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_getPrimaryActionText()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper methods
  Color _getStatusColor() {
    switch (widget.order.status.toLowerCase()) {
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

  IconData _getStatusIcon() {
    switch (widget.order.status.toLowerCase()) {
      case 'assigned':
        return Icons.assignment;
      case 'picked_up':
        return Icons.inventory;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (widget.order.status.toLowerCase()) {
      case 'assigned':
        return 'Order Assigned';
      case 'picked_up':
        return 'Order Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown Status';
    }
  }

  String _getStatusDescription() {
    switch (widget.order.status.toLowerCase()) {
      case 'assigned':
        return 'Ready for pickup from vendor';
      case 'picked_up':
        return 'Order collected, ready for delivery';
      case 'in_transit':
        return 'On the way to customer';
      case 'delivered':
        return 'Successfully delivered to customer';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return 'Status unknown';
    }
  }

  String _getPrimaryActionText() {
    switch (widget.order.status.toLowerCase()) {
      case 'assigned':
        return 'Mark as Picked Up';
      case 'picked_up':
        return 'Start Delivery';
      case 'in_transit':
        return 'Complete Delivery';
      default:
        return 'Update Status';
    }
  }

  Color _getPrimaryActionColor() {
    switch (widget.order.status.toLowerCase()) {
      case 'assigned':
        return AppColors.info;
      case 'picked_up':
        return AppColors.primary;
      case 'in_transit':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  bool _canAddNotes() {
    return ['assigned', 'picked_up', 'in_transit'].contains(widget.order.status.toLowerCase());
  }

  bool _canReportIssue() {
    return ['assigned', 'picked_up', 'in_transit'].contains(widget.order.status.toLowerCase());
  }

  // Action methods
  void _handlePrimaryAction() async {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    bool success = false;

    setState(() => _isLoading = true);

    switch (widget.order.status.toLowerCase()) {
      case 'assigned':
        success = await deliveryProvider.pickUpOrder(widget.order.id);
        break;
      case 'picked_up':
        success = await deliveryProvider.startDelivery(widget.order.id);
        break;
      case 'in_transit':
        success = await deliveryProvider.completeDelivery(
          widget.order.id,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );
        break;
    }

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // If completed, go back
        if (widget.order.status.toLowerCase() == 'in_transit') {
          Navigator.of(context).pop();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _callCustomer() {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.order.customer?.phone ?? 'customer'}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openNavigation() {
    // TODO: Implement navigation to delivery address
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening navigation...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _reportIssue() {
    // TODO: Implement issue reporting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text('Issue reporting functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAction;
  final VoidCallback? onTap;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.isAction = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isAction ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isAction)
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );

    if (isAction && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }
}

class _OrderItemTile extends StatelessWidget {
  final dynamic item; // Replace with proper OrderItem model

  const _OrderItemTile({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Name', // item.product?.name ?? 'Unknown Product'
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: 2', // 'Qty: ${item.quantity}'
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}25.00', // '${AppConstants.currencySymbol}${item.price?.toStringAsFixed(2) ?? '0.00'}'
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isDiscount;

  const _SummaryRow({
    Key? key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isDiscount ? AppColors.error : (isTotal ? AppColors.success : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}