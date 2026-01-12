import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/cart.dart';
import '../models/payment_method.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService;
  
  PaymentService(this._apiService);

  // Platform channels for native payment integration
  static const MethodChannel _googlePayChannel = MethodChannel('com.taiga.googlepay');
  static const MethodChannel _applePayChannel = MethodChannel('com.taiga.applepay');

  // Initialize payment methods availability
  Future<Map<String, bool>> getAvailablePaymentMethods() async {
    try {
      final Map<String, bool> availability = {
        'google_pay': false,
        'apple_pay': false,
        'sampath_bank': true, // Always available as web-based
        'card': true,
        'wallet': true,
      };

      // Check Google Pay availability (Android)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          final bool? isGooglePayAvailable = await _googlePayChannel.invokeMethod('isAvailable');
          availability['google_pay'] = isGooglePayAvailable ?? false;
        } catch (e) {
          debugPrint('Google Pay check failed: $e');
        }
      }

      // Check Apple Pay availability (iOS)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final bool? isApplePayAvailable = await _applePayChannel.invokeMethod('isAvailable');
          availability['apple_pay'] = isApplePayAvailable ?? false;
        } catch (e) {
          debugPrint('Apple Pay check failed: $e');
        }
      }

      return availability;
    } catch (e) {
      debugPrint('Error checking payment methods: $e');
      return {
        'google_pay': false,
        'apple_pay': false,
        'sampath_bank': true,
        'card': true,
        'wallet': true,
      };
    }
  }

  // Process Google Pay payment
  Future<PaymentResult> processGooglePay({
    required Cart cart,
    required String currencyCode,
  }) async {
    try {
      // Prepare payment request
      final paymentData = {
        'total': cart.total.toString(),
        'currency': currencyCode,
        'items': cart.items.map((item) => {
          'name': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price.toString(),
        }).toList(),
      };

      // Call native Google Pay
      final result = await _googlePayChannel.invokeMethod('processPayment', paymentData);
      
      if (result['success'] == true) {
        // Process payment on backend
        final backendResult = await _processPaymentOnBackend({
          'payment_method': 'google_pay',
          'payment_token': result['paymentToken'],
          'amount': cart.total,
          'currency': currencyCode,
          'cart_items': cart.items.map((item) => item.toJson()).toList(),
        });

        return PaymentResult(
          success: backendResult['success'] ?? false,
          transactionId: backendResult['transaction_id'],
          orderId: backendResult['order_id'],
          message: backendResult['message'] ?? 'Payment processed successfully',
          paymentMethod: 'google_pay',
        );
      } else {
        return PaymentResult(
          success: false,
          message: result['error'] ?? 'Google Pay payment failed',
          paymentMethod: 'google_pay',
        );
      }
    } catch (e) {
      debugPrint('Google Pay error: $e');
      return PaymentResult(
        success: false,
        message: 'Google Pay payment failed: $e',
        paymentMethod: 'google_pay',
      );
    }
  }

  // Process Apple Pay payment
  Future<PaymentResult> processApplePay({
    required Cart cart,
    required String currencyCode,
  }) async {
    try {
      final paymentData = {
        'total': cart.total.toString(),
        'currency': currencyCode,
        'merchantId': 'merchant.com.taiga.app',
        'items': cart.items.map((item) => {
          'name': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price.toString(),
        }).toList(),
      };

      final result = await _applePayChannel.invokeMethod('processPayment', paymentData);
      
      if (result['success'] == true) {
        final backendResult = await _processPaymentOnBackend({
          'payment_method': 'apple_pay',
          'payment_token': result['paymentToken'],
          'amount': cart.total,
          'currency': currencyCode,
          'cart_items': cart.items.map((item) => item.toJson()).toList(),
        });

        return PaymentResult(
          success: backendResult['success'] ?? false,
          transactionId: backendResult['transaction_id'],
          orderId: backendResult['order_id'],
          message: backendResult['message'] ?? 'Payment processed successfully',
          paymentMethod: 'apple_pay',
        );
      } else {
        return PaymentResult(
          success: false,
          message: result['error'] ?? 'Apple Pay payment failed',
          paymentMethod: 'apple_pay',
        );
      }
    } catch (e) {
      debugPrint('Apple Pay error: $e');
      return PaymentResult(
        success: false,
        message: 'Apple Pay payment failed: $e',
        paymentMethod: 'apple_pay',
      );
    }
  }

  // Process Sampath Bank IPG payment
  Future<PaymentResult> processSampathBank({
    required Cart cart,
    required String currencyCode,
    required Map<String, dynamic> billingDetails,
  }) async {
    try {
      // Create payment request to backend
      final response = await _apiService.post('/payments/sampath-bank/initiate', {
        'amount': cart.total,
        'currency': currencyCode,
        'cart_items': cart.items.map((item) => item.toJson()).toList(),
        'billing_details': billingDetails,
        'return_url': 'taiga://payment/success',
        'cancel_url': 'taiga://payment/cancel',
      });

      if (response['success']) {
        return PaymentResult(
          success: true,
          transactionId: response['transaction_id'],
          orderId: response['order_id'],
          message: 'Payment initiated successfully',
          paymentMethod: 'sampath_bank',
          redirectUrl: response['redirect_url'],
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Payment initiation failed',
          paymentMethod: 'sampath_bank',
        );
      }
    } catch (e) {
      debugPrint('Sampath Bank payment error: $e');
      return PaymentResult(
        success: false,
        message: 'Sampath Bank payment failed: $e',
        paymentMethod: 'sampath_bank',
      );
    }
  }

  // Process credit/debit card payment
  Future<PaymentResult> processCardPayment({
    required Cart cart,
    required String currencyCode,
    required CardDetails cardDetails,
    required Map<String, dynamic> billingDetails,
  }) async {
    try {
      final response = await _apiService.post('/payments/card/process', {
        'amount': cart.total,
        'currency': currencyCode,
        'cart_items': cart.items.map((item) => item.toJson()).toList(),
        'card_details': cardDetails.toJson(),
        'billing_details': billingDetails,
      });

      if (response['success']) {
        return PaymentResult(
          success: true,
          transactionId: response['transaction_id'],
          orderId: response['order_id'],
          message: response['message'] ?? 'Payment processed successfully',
          paymentMethod: 'card',
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Card payment failed',
          paymentMethod: 'card',
        );
      }
    } catch (e) {
      debugPrint('Card payment error: $e');
      return PaymentResult(
        success: false,
        message: 'Card payment failed: $e',
        paymentMethod: 'card',
      );
    }
  }

  // Process wallet payment
  Future<PaymentResult> processWalletPayment({
    required Cart cart,
    required String currencyCode,
  }) async {
    try {
      final response = await _apiService.post('/payments/wallet/process', {
        'amount': cart.total,
        'currency': currencyCode,
        'cart_items': cart.items.map((item) => item.toJson()).toList(),
      });

      if (response['success']) {
        return PaymentResult(
          success: true,
          transactionId: response['transaction_id'],
          orderId: response['order_id'],
          message: response['message'] ?? 'Payment processed successfully',
          paymentMethod: 'wallet',
        );
      } else {
        return PaymentResult(
          success: false,
          message: response['message'] ?? 'Insufficient wallet balance',
          paymentMethod: 'wallet',
        );
      }
    } catch (e) {
      debugPrint('Wallet payment error: $e');
      return PaymentResult(
        success: false,
        message: 'Wallet payment failed: $e',
        paymentMethod: 'wallet',
      );
    }
  }

  // Verify payment status
  Future<PaymentStatus> verifyPayment(String transactionId) async {
    try {
      final response = await _apiService.get('/payments/verify/$transactionId');
      
      return PaymentStatus.fromJson(response['data']);
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return PaymentStatus(
        transactionId: transactionId,
        status: 'failed',
        message: 'Payment verification failed',
      );
    }
  }

  // Get payment methods for user
  Future<List<PaymentMethod>> getUserPaymentMethods() async {
    try {
      final response = await _apiService.get('/user/payment-methods');
      
      if (response['success']) {
        return (response['data'] as List)
            .map((json) => PaymentMethod.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
      return [];
    }
  }

  // Add payment method
  Future<bool> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final response = await _apiService.post('/user/payment-methods', paymentMethod.toJson());
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error adding payment method: $e');
      return false;
    }
  }

  // Remove payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      final response = await _apiService.delete('/user/payment-methods/$paymentMethodId');
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error removing payment method: $e');
      return false;
    }
  }

  // Get wallet balance
  Future<double> getWalletBalance() async {
    try {
      final response = await _apiService.get('/user/wallet/balance');
      return (response['balance'] ?? 0.0).toDouble();
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  // Process backend payment
  Future<Map<String, dynamic>> _processPaymentOnBackend(Map<String, dynamic> paymentData) async {
    try {
      final response = await _apiService.post('/payments/process', paymentData);
      return response;
    } catch (e) {
      debugPrint('Backend payment processing error: $e');
      return {'success': false, 'message': 'Backend payment processing failed'};
    }
  }
}

// Payment result model
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? orderId;
  final String message;
  final String paymentMethod;
  final String? redirectUrl;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.orderId,
    required this.message,
    required this.paymentMethod,
    this.redirectUrl,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'transaction_id': transactionId,
    'order_id': orderId,
    'message': message,
    'payment_method': paymentMethod,
    'redirect_url': redirectUrl,
  };
}

// Payment status model
class PaymentStatus {
  final String transactionId;
  final String status;
  final String message;
  final DateTime? completedAt;

  PaymentStatus({
    required this.transactionId,
    required this.status,
    required this.message,
    this.completedAt,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}

// Card details model
class CardDetails {
  final String number;
  final String expiryMonth;
  final String expiryYear;
  final String cvc;
  final String holderName;

  CardDetails({
    required this.number,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvc,
    required this.holderName,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'expiry_month': expiryMonth,
    'expiry_year': expiryYear,
    'cvc': cvc,
    'holder_name': holderName,
  };
}