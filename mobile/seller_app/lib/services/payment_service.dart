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

  // Get seller payment methods
  Future<List<PaymentMethod>> getSellerPaymentMethods() async {
    try {
      final response = await _apiService.get('/seller/payment-methods');
      
      if (response['success']) {
        return (response['data'] as List)
            .map((json) => PaymentMethod.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching seller payment methods: $e');
      return [];
    }
  }

  // Add seller payout method
  Future<bool> addPayoutMethod(PaymentMethod paymentMethod) async {
    try {
      final response = await _apiService.post('/seller/payout-methods', paymentMethod.toJson());
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error adding payout method: $e');
      return false;
    }
  }

  // Request payout
  Future<bool> requestPayout({
    required double amount,
    required String paymentMethodId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/seller/payouts/request', {
        'amount': amount,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      });
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error requesting payout: $e');
      return false;
    }
  }

  // Get seller earnings
  Future<Map<String, dynamic>> getSellerEarnings() async {
    try {
      final response = await _apiService.get('/seller/earnings');
      return response['data'] ?? {};
    } catch (e) {
      debugPrint('Error fetching seller earnings: $e');
      return {};
    }
  }

  // Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    try {
      final response = await _apiService.get('/seller/payouts/history');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      debugPrint('Error fetching payout history: $e');
      return [];
    }
  }
}