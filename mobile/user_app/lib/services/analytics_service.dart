import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Dio _dio = Dio();
  bool _isInitialized = false;
  String? _baseUrl;
  String? _authToken;
  Map<String, dynamic> _sessionData = {};
  List<Map<String, dynamic>> _offlineEvents = [];
  DateTime? _sessionStartTime;

  // Analytics configuration
  bool trackingEnabled = true;
  bool debugMode = kDebugMode;
  int batchSize = 20;
  Duration flushInterval = const Duration(minutes: 5);

  // Initialize analytics service
  Future<void> initialize({
    required String baseUrl,
    String? authToken,
    Map<String, dynamic>? userProperties,
  }) async {
    if (_isInitialized) return;

    _baseUrl = baseUrl;
    _authToken = authToken;
    _sessionStartTime = DateTime.now();

    // Setup Dio interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) {
        if (debugMode) {
          debugPrint('Analytics API Error: ${error.message}');
        }
        handler.next(error);
      },
    ));

    // Set user properties
    if (userProperties != null) {
      await setUserProperties(userProperties);
    }

    // Load offline events
    await _loadOfflineEvents();

    // Start periodic flush
    _startPeriodicFlush();

    _isInitialized = true;

    // Track session start
    await trackEvent('session_start', {
      'session_id': _generateSessionId(),
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (debugMode) {
      debugPrint('Analytics service initialized');
    }
  }

  // Update authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  // Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    _sessionData.addAll(properties);
    await _persistSessionData();

    if (_isInitialized) {
      await _sendUserProperties(properties);
    }
  }

  // Track event
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (!trackingEnabled) return;

    final event = {
      'event_name': eventName,
      'properties': {
        ...(_sessionData),
        ...(properties ?? {}),
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _generateSessionId(),
        'event_id': _generateEventId(),
      },
    };

    if (_isInitialized && _isOnline()) {
      try {
        await _sendEvent(event);
        if (debugMode) {
          debugPrint('Event tracked: $eventName');
        }
      } catch (e) {
        // Store offline if failed
        _offlineEvents.add(event);
        await _persistOfflineEvents();
        if (debugMode) {
          debugPrint('Event stored offline: $eventName');
        }
      }
    } else {
      // Store offline
      _offlineEvents.add(event);
      await _persistOfflineEvents();
      if (debugMode) {
        debugPrint('Event stored offline: $eventName');
      }
    }
  }

  // Track screen view
  Future<void> trackScreenView(String screenName, [Map<String, dynamic>? properties]) async {
    await trackEvent('screen_view', {
      'screen_name': screenName,
      ...?properties,
    });
  }

  // Track user action
  Future<void> trackUserAction(String action, [Map<String, dynamic>? properties]) async {
    await trackEvent('user_action', {
      'action': action,
      ...?properties,
    });
  }

  // E-commerce tracking
  Future<void> trackPurchase({
    required String orderId,
    required double totalAmount,
    required String currency,
    required List<Map<String, dynamic>> items,
    String? paymentMethod,
    String? couponCode,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('purchase', {
      'order_id': orderId,
      'total_amount': totalAmount,
      'currency': currency,
      'item_count': items.length,
      'items': items,
      'payment_method': paymentMethod,
      'coupon_code': couponCode,
      ...?additionalProperties,
    });
  }

  Future<void> trackProductView({
    required String productId,
    required String productName,
    required String category,
    required double price,
    String? brand,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('product_view', {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'price': price,
      'brand': brand,
      ...?additionalProperties,
    });
  }

  Future<void> trackAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    String? category,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('add_to_cart', {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'category': category,
      'cart_value': price * quantity,
      ...?additionalProperties,
    });
  }

  Future<void> trackRemoveFromCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('remove_from_cart', {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      ...?additionalProperties,
    });
  }

  Future<void> trackCheckoutStart({
    required double cartValue,
    required int itemCount,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('checkout_start', {
      'cart_value': cartValue,
      'item_count': itemCount,
      'items': items,
      ...?additionalProperties,
    });
  }

  Future<void> trackSearchQuery({
    required String query,
    String? category,
    int? resultCount,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('search', {
      'search_query': query,
      'category': category,
      'result_count': resultCount,
      ...?additionalProperties,
    });
  }

  // User engagement tracking
  Future<void> trackAppOpen() async {
    await trackEvent('app_open');
  }

  Future<void> trackAppBackground() async {
    final sessionDuration = _getSessionDuration();
    await trackEvent('app_background', {
      'session_duration': sessionDuration,
    });
  }

  Future<void> trackFeatureUsage(String featureName, [Map<String, dynamic>? properties]) async {
    await trackEvent('feature_usage', {
      'feature_name': featureName,
      ...?properties,
    });
  }

  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? context,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context,
      ...?additionalProperties,
    });
  }

  // Timing events
  Future<void> trackTiming({
    required String category,
    required String variable,
    required int timeMilliseconds,
    String? label,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('timing', {
      'timing_category': category,
      'timing_variable': variable,
      'timing_value': timeMilliseconds,
      'timing_label': label,
      ...?additionalProperties,
    });
  }

  // Performance tracking
  void startPerformanceTimer(String operationName) {
    _sessionData['${operationName}_start_time'] = DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> endPerformanceTimer(String operationName, [Map<String, dynamic>? properties]) async {
    final startTimeKey = '${operationName}_start_time';
    final startTime = _sessionData[startTimeKey] as int?;
    
    if (startTime != null) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      
      await trackTiming(
        category: 'performance',
        variable: operationName,
        timeMilliseconds: duration,
        additionalProperties: properties,
      );
      
      _sessionData.remove(startTimeKey);
    }
  }

  // Conversion funnel tracking
  Future<void> trackFunnelStep({
    required String funnelName,
    required String stepName,
    required int stepNumber,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('funnel_step', {
      'funnel_name': funnelName,
      'step_name': stepName,
      'step_number': stepNumber,
      ...?additionalProperties,
    });
  }

  // A/B testing
  Future<void> trackExperiment({
    required String experimentName,
    required String variant,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('experiment_viewed', {
      'experiment_name': experimentName,
      'variant': variant,
      ...?additionalProperties,
    });
  }

  // Custom metrics
  Future<void> trackCustomMetric({
    required String metricName,
    required dynamic value,
    String? unit,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('custom_metric', {
      'metric_name': metricName,
      'metric_value': value,
      'metric_unit': unit,
      ...?additionalProperties,
    });
  }

  // Revenue tracking
  Future<void> trackRevenue({
    required double amount,
    required String currency,
    String? productId,
    String? orderId,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('revenue', {
      'revenue_amount': amount,
      'currency': currency,
      'product_id': productId,
      'order_id': orderId,
      ...?additionalProperties,
    });
  }

  // Batch operations
  Future<void> flushEvents() async {
    if (_offlineEvents.isEmpty) return;

    if (_isOnline()) {
      try {
        await _sendEventBatch(_offlineEvents);
        _offlineEvents.clear();
        await _persistOfflineEvents();
        
        if (debugMode) {
          debugPrint('Flushed ${_offlineEvents.length} offline events');
        }
      } catch (e) {
        if (debugMode) {
          debugPrint('Failed to flush events: $e');
        }
      }
    }
  }

  // Disable/Enable tracking
  void enableTracking() {
    trackingEnabled = true;
  }

  void disableTracking() {
    trackingEnabled = false;
  }

  // Session management
  String _generateSessionId() {
    return '${_sessionStartTime?.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(_sessionData.hashCode).toString()}';
  }

  int _getSessionDuration() {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inMilliseconds;
  }

  // Private methods
  bool _isOnline() {
    // Simple connectivity check - you might want to use connectivity_plus package
    return true;
  }

  Future<void> _sendEvent(Map<String, dynamic> event) async {
    await _dio.post('$_baseUrl/analytics/events', data: event);
  }

  Future<void> _sendEventBatch(List<Map<String, dynamic>> events) async {
    await _dio.post('$_baseUrl/analytics/events/batch', data: {'events': events});
  }

  Future<void> _sendUserProperties(Map<String, dynamic> properties) async {
    await _dio.post('$_baseUrl/analytics/user-properties', data: properties);
  }

  void _startPeriodicFlush() {
    Future.delayed(flushInterval, () async {
      await flushEvents();
      if (_isInitialized) {
        _startPeriodicFlush();
      }
    });
  }

  // Persistence
  Future<void> _persistSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_session_data', jsonEncode(_sessionData));
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('analytics_session_data');
    if (data != null) {
      _sessionData = Map<String, dynamic>.from(jsonDecode(data));
    }
  }

  Future<void> _persistOfflineEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_offline_events', jsonEncode(_offlineEvents));
  }

  Future<void> _loadOfflineEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('analytics_offline_events');
    if (data != null) {
      final List<dynamic> events = jsonDecode(data);
      _offlineEvents = events.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  // Cleanup
  Future<void> clearAnalyticsData() async {
    _offlineEvents.clear();
    _sessionData.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_session_data');
    await prefs.remove('analytics_offline_events');
  }

  void dispose() {
    // Track session end
    if (_isInitialized) {
      trackEvent('session_end', {
        'session_duration': _getSessionDuration(),
      });
    }
    
    // Flush remaining events
    flushEvents();
    
    _isInitialized = false;
  }
}