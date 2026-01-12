import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../home/home_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  static const String routeName = '/payment-success';

  final String orderId;
  final String transactionId;

  const PaymentSuccessScreen({
    Key? key,
    required this.orderId,
    required this.transactionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Success Animation/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 60,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Success Message
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Your order has been placed successfully.\nYou will receive a confirmation email shortly.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Order Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Order ID',
                      value: orderId,
                      isBold: true,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Transaction ID',
                      value: transactionId,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Order Date',
                      value: _formatDate(DateTime.now()),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Status',
                      value: 'Processing',
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can track your order status in the Orders section of your profile.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to order tracking
                        _navigateToOrderTracking(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Track Your Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Continue shopping
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          HomeScreen.routeName,
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Help Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Need help? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _contactSupport(context);
                    },
                    child: Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToOrderTracking(BuildContext context) {
    // TODO: Navigate to order tracking screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order tracking will be available soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For any questions about your order, please contact us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16),
                SizedBox(width: 8),
                Text('support@taiga.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16),
                SizedBox(width: 8),
                Text('+94 11 234 5678'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 16),
                SizedBox(width: 8),
                Text('24/7 Support'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open email client or phone dialer
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _DetailRow({
    Key? key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}