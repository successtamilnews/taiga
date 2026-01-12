import 'package:flutter/foundation.dart';
import '../models/payment_method.dart';
import '../models/cart.dart';
import '../services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService;

  PaymentProvider(this._paymentService);

  // State variables
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  Map<String, bool> _availablePaymentMethods = {};
  double _walletBalance = 0.0;
  PaymentResult? _lastPaymentResult;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  Map<String, bool> get availablePaymentMethods => _availablePaymentMethods;
  double get walletBalance => _walletBalance;
  PaymentResult? get lastPaymentResult => _lastPaymentResult;
  String? get error => _error;

  // Initialize payment methods
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load available payment methods
      _availablePaymentMethods = await _paymentService.getAvailablePaymentMethods();
      
      // Load user's saved payment methods
      await loadPaymentMethods();
      
      // Load wallet balance
      await loadWalletBalance();

    } catch (e) {
      _error = 'Failed to initialize payment methods: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load user's payment methods
  Future<void> loadPaymentMethods() async {
    try {
      _paymentMethods = await _paymentService.getUserPaymentMethods();
      
      // Set default payment method
      if (_selectedPaymentMethod == null && _paymentMethods.isNotEmpty) {
        _selectedPaymentMethod = _paymentMethods.firstWhere(
          (method) => method.isDefault,
          orElse: () => _paymentMethods.first,
        );
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load payment methods: $e';
      debugPrint(_error);
    }
  }

  // Load wallet balance
  Future<void> loadWalletBalance() async {
    try {
      _walletBalance = await _paymentService.getWalletBalance();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load wallet balance: $e');
    }
  }

  // Select payment method
  void selectPaymentMethod(PaymentMethod? method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  // Add payment method
  Future<bool> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final success = await _paymentService.addPaymentMethod(paymentMethod);
      
      if (success) {
        await loadPaymentMethods();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to add payment method: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  // Remove payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      final success = await _paymentService.removePaymentMethod(paymentMethodId);
      
      if (success) {
        _paymentMethods.removeWhere((method) => method.id == paymentMethodId);
        
        // If removed method was selected, select another
        if (_selectedPaymentMethod?.id == paymentMethodId) {
          _selectedPaymentMethod = _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to remove payment method: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  // Process payment with Google Pay
  Future<PaymentResult> processGooglePay({
    required Cart cart,
    required String currencyCode,
  }) async {
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentService.processGooglePay(
        cart: cart,
        currencyCode: currencyCode,
      );
      
      _lastPaymentResult = result;
      
      if (result.success) {
        await loadWalletBalance(); // Refresh wallet if needed
      }
      
      return result;
    } catch (e) {
      _error = 'Google Pay payment failed: $e';
      debugPrint(_error);
      return PaymentResult(
        success: false,
        message: _error!,
        paymentMethod: 'google_pay',
      );
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  // Process payment with Apple Pay
  Future<PaymentResult> processApplePay({
    required Cart cart,
    required String currencyCode,
  }) async {
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentService.processApplePay(
        cart: cart,
        currencyCode: currencyCode,
      );
      
      _lastPaymentResult = result;
      
      if (result.success) {
        await loadWalletBalance();
      }
      
      return result;
    } catch (e) {
      _error = 'Apple Pay payment failed: $e';
      debugPrint(_error);
      return PaymentResult(
        success: false,
        message: _error!,
        paymentMethod: 'apple_pay',
      );
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  // Process payment with Sampath Bank
  Future<PaymentResult> processSampathBank({
    required Cart cart,
    required String currencyCode,
    required Map<String, dynamic> billingDetails,
  }) async {
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentService.processSampathBank(
        cart: cart,
        currencyCode: currencyCode,
        billingDetails: billingDetails,
      );
      
      _lastPaymentResult = result;
      return result;
    } catch (e) {
      _error = 'Sampath Bank payment failed: $e';
      debugPrint(_error);
      return PaymentResult(
        success: false,
        message: _error!,
        paymentMethod: 'sampath_bank',
      );
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  // Process card payment
  Future<PaymentResult> processCardPayment({
    required Cart cart,
    required String currencyCode,
    required CardDetails cardDetails,
    required Map<String, dynamic> billingDetails,
  }) async {
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentService.processCardPayment(
        cart: cart,
        currencyCode: currencyCode,
        cardDetails: cardDetails,
        billingDetails: billingDetails,
      );
      
      _lastPaymentResult = result;
      return result;
    } catch (e) {
      _error = 'Card payment failed: $e';
      debugPrint(_error);
      return PaymentResult(
        success: false,
        message: _error!,
        paymentMethod: 'card',
      );
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  // Process wallet payment
  Future<PaymentResult> processWalletPayment({
    required Cart cart,
    required String currencyCode,
  }) async {
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      // Check wallet balance first
      if (_walletBalance < cart.total) {
        _error = 'Insufficient wallet balance';
        return PaymentResult(
          success: false,
          message: _error!,
          paymentMethod: 'wallet',
        );
      }

      final result = await _paymentService.processWalletPayment(
        cart: cart,
        currencyCode: currencyCode,
      );
      
      _lastPaymentResult = result;
      
      if (result.success) {
        await loadWalletBalance(); // Refresh balance
      }
      
      return result;
    } catch (e) {
      _error = 'Wallet payment failed: $e';
      debugPrint(_error);
      return PaymentResult(
        success: false,
        message: _error!,
        paymentMethod: 'wallet',
      );
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  // Process payment with selected method
  Future<PaymentResult> processPayment({
    required Cart cart,
    required String currencyCode,
    Map<String, dynamic>? billingDetails,
    CardDetails? cardDetails,
  }) async {
    if (_selectedPaymentMethod == null) {
      _error = 'No payment method selected';
      notifyListeners();
      return PaymentResult(
        success: false,
        message: _error!,
        paymentMethod: 'unknown',
      );
    }

    switch (_selectedPaymentMethod!.type) {
      case 'google_pay':
        return await processGooglePay(cart: cart, currencyCode: currencyCode);
      
      case 'apple_pay':
        return await processApplePay(cart: cart, currencyCode: currencyCode);
      
      case 'sampath_bank':
        return await processSampathBank(
          cart: cart,
          currencyCode: currencyCode,
          billingDetails: billingDetails ?? {},
        );
      
      case 'card':
        if (cardDetails == null) {
          _error = 'Card details required';
          notifyListeners();
          return PaymentResult(
            success: false,
            message: _error!,
            paymentMethod: 'card',
          );
        }
        return await processCardPayment(
          cart: cart,
          currencyCode: currencyCode,
          cardDetails: cardDetails,
          billingDetails: billingDetails ?? {},
        );
      
      case 'wallet':
        return await processWalletPayment(cart: cart, currencyCode: currencyCode);
      
      default:
        _error = 'Unsupported payment method: ${_selectedPaymentMethod!.type}';
        notifyListeners();
        return PaymentResult(
          success: false,
          message: _error!,
          paymentMethod: _selectedPaymentMethod!.type,
        );
    }
  }

  // Verify payment status
  Future<PaymentStatus> verifyPayment(String transactionId) async {
    try {
      return await _paymentService.verifyPayment(transactionId);
    } catch (e) {
      debugPrint('Payment verification failed: $e');
      return PaymentStatus(
        transactionId: transactionId,
        status: 'failed',
        message: 'Verification failed: $e',
      );
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear payment result
  void clearPaymentResult() {
    _lastPaymentResult = null;
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _isLoading = false;
    _isProcessingPayment = false;
    _paymentMethods.clear();
    _selectedPaymentMethod = null;
    _availablePaymentMethods.clear();
    _walletBalance = 0.0;
    _lastPaymentResult = null;
    _error = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    reset();
    super.dispose();
  }
}