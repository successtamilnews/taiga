import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/payment_method.dart';
import '../../services/payment_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_button.dart';
import 'payment_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  static const String routeName = '/checkout';

  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Payment form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardNameController = TextEditingController();

  bool _isLoading = false;
  String _selectedDeliveryOption = 'standard';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    await paymentProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                _buildOrderSummary(),
                
                const SizedBox(height: 24),
                
                // Delivery Address
                _buildDeliveryAddress(),
                
                const SizedBox(height: 24),
                
                // Delivery Options
                _buildDeliveryOptions(),
                
                const SizedBox(height: 24),
                
                // Payment Methods
                _buildPaymentMethods(),
                
                const SizedBox(height: 24),
                
                // Order Notes
                _buildOrderNotes(),
                
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOrderSummary() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              ...cartProvider.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.product.image != null
                            ? Image.network(
                                item.product.image!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${AppConstants.currencySymbol}${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
              
              const Divider(),
              
              _SummaryRow(
                label: 'Subtotal',
                value: '${AppConstants.currencySymbol}${cartProvider.subtotal.toStringAsFixed(2)}',
              ),
              _SummaryRow(
                label: 'Delivery Fee',
                value: '${AppConstants.currencySymbol}${cartProvider.deliveryFee.toStringAsFixed(2)}',
              ),
              _SummaryRow(
                label: 'Tax',
                value: '${AppConstants.currencySymbol}${cartProvider.tax.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Total',
                value: '${AppConstants.currencySymbol}${cartProvider.total.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Complete Address',
              hintText: 'Enter your delivery address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter delivery address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          _DeliveryOption(
            value: 'standard',
            groupValue: _selectedDeliveryOption,
            title: 'Standard Delivery',
            subtitle: '3-5 business days',
            price: 'Free',
            onChanged: (value) {
              setState(() {
                _selectedDeliveryOption = value!;
              });
            },
          ),
          
          _DeliveryOption(
            value: 'express',
            groupValue: _selectedDeliveryOption,
            title: 'Express Delivery',
            subtitle: '1-2 business days',
            price: '${AppConstants.currencySymbol}5.00',
            onChanged: (value) {
              setState(() {
                _selectedDeliveryOption = value!;
              });
            },
          ),
          
          _DeliveryOption(
            value: 'same_day',
            groupValue: _selectedDeliveryOption,
            title: 'Same Day Delivery',
            subtitle: 'Within 24 hours',
            price: '${AppConstants.currencySymbol}10.00',
            onChanged: (value) {
              setState(() {
                _selectedDeliveryOption = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Add payment method
                    },
                    child: const Text('Add New'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (paymentProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (paymentProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paymentProvider.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              else ...[
                // Available payment methods
                if (paymentProvider.availablePaymentMethods['google_pay'] == true)
                  _PaymentMethodTile(
                    icon: Icons.payment,
                    title: 'Google Pay',
                    subtitle: 'Pay with Google Pay',
                    isSelected: paymentProvider.selectedPaymentMethod?.type == 'google_pay',
                    onTap: () => paymentProvider.selectPaymentMethod(
                      PaymentMethod(
                        id: 'google_pay',
                        type: 'google_pay',
                        name: 'Google Pay',
                        displayName: 'Google Pay',
                        createdAt: DateTime.now(),
                      ),
                    ),
                  ),
                
                if (paymentProvider.availablePaymentMethods['apple_pay'] == true)
                  _PaymentMethodTile(
                    icon: Icons.payment,
                    title: 'Apple Pay',
                    subtitle: 'Pay with Apple Pay',
                    isSelected: paymentProvider.selectedPaymentMethod?.type == 'apple_pay',
                    onTap: () => paymentProvider.selectPaymentMethod(
                      PaymentMethod(
                        id: 'apple_pay',
                        type: 'apple_pay',
                        name: 'Apple Pay',
                        displayName: 'Apple Pay',
                        createdAt: DateTime.now(),
                      ),
                    ),
                  ),
                
                _PaymentMethodTile(
                  icon: Icons.account_balance,
                  title: 'Sampath Bank',
                  subtitle: 'Pay with internet banking',
                  isSelected: paymentProvider.selectedPaymentMethod?.type == 'sampath_bank',
                  onTap: () => paymentProvider.selectPaymentMethod(
                    PaymentMethod(
                      id: 'sampath_bank',
                      type: 'sampath_bank',
                      name: 'Sampath Bank',
                      displayName: 'Sampath Bank IPG',
                      createdAt: DateTime.now(),
                    ),
                  ),
                ),
                
                _PaymentMethodTile(
                  icon: Icons.account_balance_wallet,
                  title: 'Taiga Wallet',
                  subtitle: 'Balance: ${AppConstants.currencySymbol}${paymentProvider.walletBalance.toStringAsFixed(2)}',
                  isSelected: paymentProvider.selectedPaymentMethod?.type == 'wallet',
                  onTap: () => paymentProvider.selectPaymentMethod(
                    PaymentMethod(
                      id: 'wallet',
                      type: 'wallet',
                      name: 'Wallet',
                      displayName: 'Taiga Wallet',
                      createdAt: DateTime.now(),
                    ),
                  ),
                ),
                
                _PaymentMethodTile(
                  icon: Icons.credit_card,
                  title: 'Credit/Debit Card',
                  subtitle: 'Pay with card',
                  isSelected: paymentProvider.selectedPaymentMethod?.type == 'card',
                  onTap: () => paymentProvider.selectPaymentMethod(
                    PaymentMethod(
                      id: 'card',
                      type: 'card',
                      name: 'Card',
                      displayName: 'Credit/Debit Card',
                      createdAt: DateTime.now(),
                    ),
                  ),
                ),
                
                // Card details form (show if card is selected)
                if (paymentProvider.selectedPaymentMethod?.type == 'card') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildCardForm(),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter card number';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'MM/YY',
                  hintText: '12/25',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvcController,
                decoration: const InputDecoration(
                  labelText: 'CVC',
                  hintText: '123',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _cardNameController,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOrderNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Notes (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add any special instructions for your order...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Consumer2<CartProvider, PaymentProvider>(
        builder: (context, cartProvider, paymentProvider, child) {
          return CustomButton(
            text: 'Place Order • ${AppConstants.currencySymbol}${cartProvider.total.toStringAsFixed(2)}',
            onPressed: paymentProvider.isProcessingPayment ? null : _placeOrder,
            isLoading: paymentProvider.isProcessingPayment,
          );
        },
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (paymentProvider.selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare billing details
      final billingDetails = {
        'name': authProvider.user?.name ?? '',
        'email': authProvider.user?.email ?? '',
        'phone': authProvider.user?.phone ?? '',
        'address': _addressController.text.trim(),
      };

      CardDetails? cardDetails;
      if (paymentProvider.selectedPaymentMethod!.type == 'card') {
        cardDetails = CardDetails(
          number: _cardNumberController.text.trim(),
          expiryMonth: _expiryController.text.split('/')[0],
          expiryYear: _expiryController.text.split('/')[1],
          cvc: _cvcController.text.trim(),
          holderName: _cardNameController.text.trim(),
        );
      }

      // Process payment
      final result = await paymentProvider.processPayment(
        cart: cartProvider.cart,
        currencyCode: 'LKR',
        billingDetails: billingDetails,
        cardDetails: cardDetails,
      );

      if (result.success) {
        // Clear cart
        cartProvider.clearCart();
        
        // Navigate to success screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                orderId: result.orderId!,
                transactionId: result.transactionId!,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Helper Widgets
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    Key? key,
    required this.label,
    required this.value,
    this.isTotal = false,
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
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final String price;
  final ValueChanged<String?> onChanged;

  const _DeliveryOption({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: value == groupValue 
              ? AppColors.primary 
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        secondary: Text(
          price,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary),
      ),
    );
  }
}