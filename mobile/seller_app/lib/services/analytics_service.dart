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
      'app_type': 'seller',
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (debugMode) {
      debugPrint('Analytics service initialized for Seller App');
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
        'app_type': 'seller',
      },
    };

    if (_isInitialized && _isOnline()) {
      try {
        await _sendEvent(event);
        if (debugMode) {
          debugPrint('Event tracked: $eventName');
        }
      } catch (e) {
        _offlineEvents.add(event);
        await _persistOfflineEvents();
        if (debugMode) {
          debugPrint('Event stored offline: $eventName');
        }
      }
    } else {
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

  // Seller-specific analytics
  
  // Product management analytics
  Future<void> trackProductAction({
    required String action, // 'add', 'edit', 'delete', 'view'
    required String productId,
    String? productName,
    String? category,
    double? price,
    int? stockQuantity,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_product_action', {
      'action': action,
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'price': price,
      'stock_quantity': stockQuantity,
      ...?additionalProperties,
    });
  }

  // Order management analytics
  Future<void> trackOrderAction({
    required String action, // 'accept', 'reject', 'prepare', 'ready', 'complete'
    required String orderId,
    required double orderValue,
    required int itemCount,
    String? customerId,
    String? paymentMethod,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_order_action', {
      'action': action,
      'order_id': orderId,
      'order_value': orderValue,
      'item_count': itemCount,
      'customer_id': customerId,
      'payment_method': paymentMethod,
      ...?additionalProperties,
    });
  }

  // Inventory analytics
  Future<void> trackInventoryUpdate({
    required String productId,
    required int oldQuantity,
    required int newQuantity,
    required String updateReason, // 'sale', 'restock', 'adjustment', 'damage'
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_inventory_update', {
      'product_id': productId,
      'old_quantity': oldQuantity,
      'new_quantity': newQuantity,
      'quantity_change': newQuantity - oldQuantity,
      'update_reason': updateReason,
      ...?additionalProperties,
    });
  }

  // Sales analytics
  Future<void> trackSale({
    required String orderId,
    required double saleAmount,
    required double commission,
    required double netEarnings,
    required List<Map<String, dynamic>> items,
    String? paymentMethod,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_sale', {
      'order_id': orderId,
      'sale_amount': saleAmount,
      'commission': commission,
      'net_earnings': netEarnings,
      'item_count': items.length,
      'items': items,
      'payment_method': paymentMethod,
      ...?additionalProperties,
    });
  }

  // Customer interaction analytics
  Future<void> trackCustomerInteraction({
    required String interactionType, // 'message', 'call', 'review_response', 'complaint_resolution'
    required String customerId,
    String? orderId,
    String? messageContent,
    int? responseTimeMinutes,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_customer_interaction', {
      'interaction_type': interactionType,
      'customer_id': customerId,
      'order_id': orderId,
      'message_content': messageContent,
      'response_time_minutes': responseTimeMinutes,
      ...?additionalProperties,
    });
  }

  // Store management analytics
  Future<void> trackStoreUpdate({
    required String updateType, // 'hours', 'info', 'policies', 'delivery_zones'
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_store_update', {
      'update_type': updateType,
      'old_values': oldValues,
      'new_values': newValues,
      ...?additionalProperties,
    });
  }

  // Promotion analytics
  Future<void> trackPromotionAction({
    required String action, // 'create', 'edit', 'activate', 'deactivate', 'delete'
    required String promotionId,
    String? promotionType, // 'discount', 'coupon', 'bundle', 'bogo'
    double? discountValue,
    String? discountType, // 'percentage', 'fixed'
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_promotion_action', {
      'action': action,
      'promotion_id': promotionId,
      'promotion_type': promotionType,
      'discount_value': discountValue,
      'discount_type': discountType,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      ...?additionalProperties,
    });
  }

  // Performance analytics
  Future<void> trackPerformanceMetrics({
    required String period, // 'daily', 'weekly', 'monthly'
    required double totalRevenue,
    required int totalOrders,
    required double averageOrderValue,
    required double sellerRating,
    required int totalProducts,
    required int lowStockProducts,
    Map<String, dynamic>? additionalMetrics,
  }) async {
    await trackEvent('seller_performance_metrics', {
      'period': period,
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'average_order_value': averageOrderValue,
      'seller_rating': sellerRating,
      'total_products': totalProducts,
      'low_stock_products': lowStockProducts,
      'conversion_rate': totalOrders > 0 ? (totalRevenue / totalOrders) : 0,
      ...?additionalMetrics,
    });
  }

  // Dashboard analytics
  Future<void> trackDashboardView({
    required String dashboardSection, // 'overview', 'orders', 'products', 'analytics', 'settings'
    int? viewDurationSeconds,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_dashboard_view', {
      'dashboard_section': dashboardSection,
      'view_duration_seconds': viewDurationSeconds,
      ...?additionalProperties,
    });
  }

  // App usage analytics
  Future<void> trackAppOpen() async {
    await trackEvent('seller_app_open');
  }

  Future<void> trackAppBackground() async {
    final sessionDuration = _getSessionDuration();
    await trackEvent('seller_app_background', {
      'session_duration': sessionDuration,
    });
  }

  Future<void> trackFeatureUsage(String featureName, [Map<String, dynamic>? properties]) async {
    await trackEvent('seller_feature_usage', {
      'feature_name': featureName,
      ...?properties,
    });
  }

  // Error tracking
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? context,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context,
      ...?additionalProperties,
    });
  }

  // Search analytics
  Future<void> trackSearch({
    required String searchQuery,
    required String searchType, // 'product', 'order', 'customer'
    int? resultCount,
    bool? hasFilters,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_search', {
      'search_query': searchQuery,
      'search_type': searchType,
      'result_count': resultCount,
      'has_filters': hasFilters,
      'filters': filters,
      ...?additionalProperties,
    });
  }

  // Notification analytics
  Future<void> trackNotificationInteraction({
    required String notificationType,
    required String action, // 'received', 'opened', 'dismissed'
    String? notificationId,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_notification_interaction', {
      'notification_type': notificationType,
      'action': action,
      'notification_id': notificationId,
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
    await trackEvent('seller_timing', {
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
        category: 'seller_performance',
        variable: operationName,
        timeMilliseconds: duration,
        additionalProperties: properties,
      );
      
      _sessionData.remove(startTimeKey);
    }
  }

  // Revenue tracking
  Future<void> trackRevenue({
    required double amount,
    required String currency,
    String? productId,
    String? orderId,
    String? revenueType, // 'sale', 'commission', 'bonus'
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_revenue', {
      'revenue_amount': amount,
      'currency': currency,
      'product_id': productId,
      'order_id': orderId,
      'revenue_type': revenueType,
      ...?additionalProperties,
    });
  }

  // Custom metrics for sellers
  Future<void> trackCustomSellerMetric({
    required String metricName,
    required dynamic value,
    String? unit,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('seller_custom_metric', {
      'metric_name': metricName,
      'metric_value': value,
      'metric_unit': unit,
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
    return true; // Simple connectivity check
  }

  Future<void> _sendEvent(Map<String, dynamic> event) async {
    await _dio.post('$_baseUrl/api/analytics/events', data: event);
  }

  Future<void> _sendEventBatch(List<Map<String, dynamic>> events) async {
    await _dio.post('$_baseUrl/api/analytics/events/batch', data: {'events': events});
  }

  Future<void> _sendUserProperties(Map<String, dynamic> properties) async {
    await _dio.post('$_baseUrl/api/analytics/user-properties', data: properties);
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
    await prefs.setString('analytics_session_data_seller', jsonEncode(_sessionData));
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('analytics_session_data_seller');
    if (data != null) {
      _sessionData = Map<String, dynamic>.from(jsonDecode(data));
    }
  }

  Future<void> _persistOfflineEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_offline_events_seller', jsonEncode(_offlineEvents));
  }

  Future<void> _loadOfflineEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('analytics_offline_events_seller');
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
    await prefs.remove('analytics_session_data_seller');
    await prefs.remove('analytics_offline_events_seller');
  }

  void dispose() {
    if (_isInitialized) {
      trackEvent('seller_session_end', {
        'session_duration': _getSessionDuration(),
      });
    }
    
    flushEvents();
    _isInitialized = false;
  }
}