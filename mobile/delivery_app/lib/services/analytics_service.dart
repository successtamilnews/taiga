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
      'app_type': 'delivery',
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (debugMode) {
      debugPrint('Analytics service initialized for Delivery App');
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
        'app_type': 'delivery',
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

  // Delivery-specific analytics
  
  // Delivery assignment analytics
  Future<void> trackDeliveryAssignment({
    required String action, // 'received', 'accepted', 'rejected'
    required String deliveryId,
    String? orderId,
    double? distance,
    double? estimatedTime,
    String? rejectionReason,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('delivery_assignment', {
      'action': action,
      'delivery_id': deliveryId,
      'order_id': orderId,
      'distance_km': distance,
      'estimated_time_minutes': estimatedTime,
      'rejection_reason': rejectionReason,
      ...?additionalProperties,
    });
  }

  // Delivery performance analytics
  Future<void> trackDeliveryCompletion({
    required String deliveryId,
    required String orderId,
    required double actualTime,
    required double estimatedTime,
    required double distance,
    required String completionMethod, // 'contactless', 'signature', 'code'
    bool? onTime,
    String? customerRating,
    String? feedback,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('delivery_completion', {
      'delivery_id': deliveryId,
      'order_id': orderId,
      'actual_time_minutes': actualTime,
      'estimated_time_minutes': estimatedTime,
      'time_variance_minutes': actualTime - estimatedTime,
      'distance_km': distance,
      'completion_method': completionMethod,
      'on_time': onTime ?? (actualTime <= estimatedTime * 1.1),
      'customer_rating': customerRating,
      'feedback': feedback,
      'delivery_efficiency': estimatedTime > 0 ? (estimatedTime / actualTime) : 1.0,
      ...?additionalProperties,
    });
  }

  // Location and route analytics
  Future<void> trackLocationUpdate({
    required double latitude,
    required double longitude,
    required double accuracy,
    double? speed,
    double? heading,
    String? deliveryId,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('location_update', {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracy,
      'speed_kmh': speed,
      'heading_degrees': heading,
      'delivery_id': deliveryId,
      ...?additionalProperties,
    });
  }

  Future<void> trackRouteOptimization({
    required List<String> deliveryIds,
    required double originalDistance,
    required double optimizedDistance,
    required double timeSaved,
    String? optimizationType, // 'automatic', 'manual'
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('route_optimization', {
      'delivery_count': deliveryIds.length,
      'delivery_ids': deliveryIds,
      'original_distance_km': originalDistance,
      'optimized_distance_km': optimizedDistance,
      'distance_saved_km': originalDistance - optimizedDistance,
      'time_saved_minutes': timeSaved,
      'optimization_efficiency': originalDistance > 0 ? 
        ((originalDistance - optimizedDistance) / originalDistance) * 100 : 0,
      'optimization_type': optimizationType,
      ...?additionalProperties,
    });
  }

  // Traffic and navigation analytics
  Future<void> trackTrafficIncident({
    required String incidentType, // 'accident', 'construction', 'heavy_traffic'
    required double latitude,
    required double longitude,
    required String action, // 'reported', 'avoided', 'encountered'
    String? severity,
    int? delayMinutes,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('traffic_incident', {
      'incident_type': incidentType,
      'latitude': latitude,
      'longitude': longitude,
      'action': action,
      'severity': severity,
      'delay_minutes': delayMinutes,
      ...?additionalProperties,
    });
  }

  Future<void> trackNavigationEvent({
    required String eventType, // 'route_started', 'route_deviated', 'destination_reached'
    String? deliveryId,
    double? deviationDistance,
    String? reason,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('navigation_event', {
      'event_type': eventType,
      'delivery_id': deliveryId,
      'deviation_distance_meters': deviationDistance,
      'reason': reason,
      ...?additionalProperties,
    });
  }

  // Customer interaction analytics
  Future<void> trackCustomerInteraction({
    required String interactionType, // 'call', 'message', 'meeting'
    required String customerId,
    required String deliveryId,
    int? duration,
    String? outcome,
    String? notes,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('customer_interaction', {
      'interaction_type': interactionType,
      'customer_id': customerId,
      'delivery_id': deliveryId,
      'duration_seconds': duration,
      'outcome': outcome,
      'notes': notes,
      ...?additionalProperties,
    });
  }

  // Earnings and payment analytics
  Future<void> trackEarnings({
    required String deliveryId,
    required double baseAmount,
    required double tipAmount,
    required double bonusAmount,
    required double totalAmount,
    String? paymentMethod,
    DateTime? paymentDate,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('delivery_earnings', {
      'delivery_id': deliveryId,
      'base_amount': baseAmount,
      'tip_amount': tipAmount,
      'bonus_amount': bonusAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate?.toIso8601String(),
      'tip_percentage': baseAmount > 0 ? (tipAmount / baseAmount) * 100 : 0,
      ...?additionalProperties,
    });
  }

  // Vehicle and fuel analytics
  Future<void> trackVehicleUsage({
    required String vehicleType, // 'bike', 'scooter', 'car', 'van'
    required double distanceTraveled,
    required double fuelUsed,
    required int deliveryCount,
    double? fuelCost,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('vehicle_usage', {
      'vehicle_type': vehicleType,
      'distance_km': distanceTraveled,
      'fuel_used_liters': fuelUsed,
      'delivery_count': deliveryCount,
      'fuel_cost': fuelCost,
      'fuel_efficiency': distanceTraveled > 0 ? 
        distanceTraveled / (fuelUsed > 0 ? fuelUsed : 1) : 0,
      'deliveries_per_km': distanceTraveled > 0 ? 
        deliveryCount / distanceTraveled : 0,
      ...?additionalProperties,
    });
  }

  // Working hours and availability analytics
  Future<void> trackWorkingSession({
    required DateTime startTime,
    required DateTime endTime,
    required int deliveriesCompleted,
    required double totalEarnings,
    required double distanceTraveled,
    String? endReason, // 'completed_shift', 'break', 'emergency'
    Map<String, dynamic>? additionalProperties,
  }) async {
    final duration = endTime.difference(startTime);
    
    await trackEvent('working_session', {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': duration.inMinutes,
      'deliveries_completed': deliveriesCompleted,
      'total_earnings': totalEarnings,
      'distance_traveled_km': distanceTraveled,
      'end_reason': endReason,
      'deliveries_per_hour': duration.inHours > 0 ? 
        deliveriesCompleted / duration.inHours : 0,
      'earnings_per_hour': duration.inHours > 0 ? 
        totalEarnings / duration.inHours : 0,
      'earnings_per_delivery': deliveriesCompleted > 0 ? 
        totalEarnings / deliveriesCompleted : 0,
      ...?additionalProperties,
    });
  }

  Future<void> trackAvailabilityChange({
    required bool isAvailable,
    String? reason,
    String? location,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('availability_change', {
      'is_available': isAvailable,
      'reason': reason,
      'location': location,
      ...?additionalProperties,
    });
  }

  // Issue and incident analytics
  Future<void> trackDeliveryIssue({
    required String issueType, // 'address_not_found', 'customer_unavailable', 'damaged_item'
    required String deliveryId,
    required String severity, // 'low', 'medium', 'high'
    required String resolution, // 'resolved', 'escalated', 'cancelled'
    int? resolutionTime,
    String? description,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('delivery_issue', {
      'issue_type': issueType,
      'delivery_id': deliveryId,
      'severity': severity,
      'resolution': resolution,
      'resolution_time_minutes': resolutionTime,
      'description': description,
      ...?additionalProperties,
    });
  }

  // App usage analytics
  Future<void> trackAppOpen() async {
    await trackEvent('delivery_app_open');
  }

  Future<void> trackAppBackground() async {
    final sessionDuration = _getSessionDuration();
    await trackEvent('delivery_app_background', {
      'session_duration': sessionDuration,
    });
  }

  Future<void> trackFeatureUsage(String featureName, [Map<String, dynamic>? properties]) async {
    await trackEvent('delivery_feature_usage', {
      'feature_name': featureName,
      ...?properties,
    });
  }

  // Map and navigation feature analytics
  Future<void> trackMapInteraction({
    required String action, // 'zoom', 'pan', 'route_view', 'satellite_toggle'
    double? latitude,
    double? longitude,
    int? zoomLevel,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('map_interaction', {
      'action': action,
      'latitude': latitude,
      'longitude': longitude,
      'zoom_level': zoomLevel,
      ...?additionalProperties,
    });
  }

  // Performance and efficiency metrics
  Future<void> trackDeliveryEfficiencyMetrics({
    required String period, // 'daily', 'weekly', 'monthly'
    required int totalDeliveries,
    required double totalDistance,
    required double totalTime,
    required double totalEarnings,
    required double averageRating,
    required int onTimeDeliveries,
    Map<String, dynamic>? additionalMetrics,
  }) async {
    await trackEvent('delivery_efficiency_metrics', {
      'period': period,
      'total_deliveries': totalDeliveries,
      'total_distance_km': totalDistance,
      'total_time_hours': totalTime,
      'total_earnings': totalEarnings,
      'average_rating': averageRating,
      'on_time_deliveries': onTimeDeliveries,
      'on_time_percentage': totalDeliveries > 0 ? 
        (onTimeDeliveries / totalDeliveries) * 100 : 0,
      'deliveries_per_hour': totalTime > 0 ? totalDeliveries / totalTime : 0,
      'earnings_per_hour': totalTime > 0 ? totalEarnings / totalTime : 0,
      'earnings_per_km': totalDistance > 0 ? totalEarnings / totalDistance : 0,
      ...?additionalMetrics,
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
    await trackEvent('delivery_error', {
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
    await trackEvent('delivery_timing', {
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
        category: 'delivery_performance',
        variable: operationName,
        timeMilliseconds: duration,
        additionalProperties: properties,
      );
      
      _sessionData.remove(startTimeKey);
    }
  }

  // Custom metrics for delivery personnel
  Future<void> trackCustomDeliveryMetric({
    required String metricName,
    required dynamic value,
    String? unit,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await trackEvent('delivery_custom_metric', {
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
    await prefs.setString('analytics_session_data_delivery', jsonEncode(_sessionData));
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('analytics_session_data_delivery');
    if (data != null) {
      _sessionData = Map<String, dynamic>.from(jsonDecode(data));
    }
  }

  Future<void> _persistOfflineEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_offline_events_delivery', jsonEncode(_offlineEvents));
  }

  Future<void> _loadOfflineEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('analytics_offline_events_delivery');
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
    await prefs.remove('analytics_session_data_delivery');
    await prefs.remove('analytics_offline_events_delivery');
  }

  void dispose() {
    if (_isInitialized) {
      trackEvent('delivery_session_end', {
        'session_duration': _getSessionDuration(),
      });
    }
    
    flushEvents();
    _isInitialized = false;
  }
}