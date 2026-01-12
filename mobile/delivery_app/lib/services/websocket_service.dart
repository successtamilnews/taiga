import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'dart:async';

class WebSocketEvents {
  static const String connectionStatus = 'connection_status';
  static const String newDeliveryAssignment = 'new_delivery_assignment';
  static const String deliveryUpdate = 'delivery_update';
  static const String routeOptimization = 'route_optimization';
  static const String locationUpdate = 'location_update';
  static const String customerMessage = 'customer_message';
  static const String trafficAlert = 'traffic_alert';
  static const String deliveryComplete = 'delivery_complete';
  static const String emergencyAlert = 'emergency_alert';
  static const String paymentUpdate = 'payment_update';
  static const String systemMaintenance = 'system_maintenance';
  static const String chatMessage = 'chat_message';
}

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  String? _wsUrl;
  String? _authToken;
  String? _deliveryPersonId;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _locationUpdateTimer;
  
  // Connection statistics
  int _connectionAttempts = 0;
  DateTime? _lastConnected;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  
  // Event listeners
  final Map<String, List<Function(Map<String, dynamic>)>> _eventListeners = {};
  
  // Message queue for offline scenarios
  final List<Map<String, dynamic>> _messageQueue = [];
  
  // Current subscriptions
  final Set<String> _subscriptions = {};
  
  // Current location for automatic updates
  Map<String, double>? _currentLocation;
  bool _locationSharingEnabled = false;

  // Getters
  bool get isConnected => _isConnected;
  bool get locationSharingEnabled => _locationSharingEnabled;
  int get connectionAttempts => _connectionAttempts;
  DateTime? get lastConnected => _lastConnected;
  Map<String, double>? get currentLocation => _currentLocation;

  // Initialize WebSocket connection
  Future<void> initialize({
    required String wsUrl,
    required String authToken,
    required String deliveryPersonId,
  }) async {
    _wsUrl = wsUrl;
    _authToken = authToken;
    _deliveryPersonId = deliveryPersonId;
    
    await _connect();
  }

  // Connect to WebSocket
  Future<void> _connect() async {
    if (_isConnected || _wsUrl == null) return;

    try {
      _connectionAttempts++;
      
      final uri = Uri.parse('$_wsUrl?token=$_authToken&type=delivery&delivery_person_id=$_deliveryPersonId');
      _channel = WebSocketChannel.connect(uri);
      
      // Listen to the channel
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );
      
      _isConnected = true;
      _lastConnected = DateTime.now();
      
      // Start heartbeat
      _startHeartbeat();
      
      // Send queued messages
      _sendQueuedMessages();
      
      // Start location sharing if enabled
      if (_locationSharingEnabled) {
        _startLocationUpdates();
      }
      
      // Notify connection status
      _notifyListeners(WebSocketEvents.connectionStatus, {
        'connected': true,
        'timestamp': DateTime.now().toIso8601String(),
        'delivery_person_id': _deliveryPersonId,
      });
      
      if (kDebugMode) {
        debugPrint('WebSocket connected (Delivery App) - ID: $_deliveryPersonId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WebSocket connection error: $e');
      }
      
      _scheduleReconnect();
    }
  }

  // Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      _messagesReceived++;
      final Map<String, dynamic> data = jsonDecode(message);
      final eventType = data['type'] as String?;
      
      if (eventType != null) {
        _notifyListeners(eventType, data);
      }
      
      if (kDebugMode) {
        debugPrint('WebSocket message received (Delivery): $eventType');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing WebSocket message: $e');
      }
    }
  }

  // Handle connection errors
  void _onError(error) {
    if (kDebugMode) {
      debugPrint('WebSocket error: $error');
    }
    
    _notifyListeners(WebSocketEvents.connectionStatus, {
      'connected': false,
      'error': error.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Handle disconnection
  void _onDisconnected() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _locationUpdateTimer?.cancel();
    
    _notifyListeners(WebSocketEvents.connectionStatus, {
      'connected': false,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (kDebugMode) {
      debugPrint('WebSocket disconnected (Delivery App)');
    }
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  // Send message
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_isConnected && _channel != null) {
      try {
        final enrichedMessage = {
          ...message,
          'delivery_person_id': _deliveryPersonId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        final jsonMessage = jsonEncode(enrichedMessage);
        _channel!.sink.add(jsonMessage);
        _messagesSent++;
        
        if (kDebugMode) {
          debugPrint('WebSocket message sent (Delivery): ${message['type']}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error sending WebSocket message: $e');
        }
        
        // Queue message for retry
        _messageQueue.add(message);
      }
    } else {
      // Queue message for when connected
      _messageQueue.add(message);
    }
  }

  // Send queued messages
  void _sendQueuedMessages() {
    while (_messageQueue.isNotEmpty && _isConnected) {
      final message = _messageQueue.removeAt(0);
      _sendMessage(message);
    }
  }

  // Heartbeat functionality
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendMessage({
          'type': 'ping',
          'delivery_status': 'online',
          'location': _currentLocation,
        });
      }
    });
  }

  // Location update functionality
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isConnected && _locationSharingEnabled && _currentLocation != null) {
        _sendMessage({
          'type': 'location_update',
          'latitude': _currentLocation!['latitude'],
          'longitude': _currentLocation!['longitude'],
          'accuracy': _currentLocation!['accuracy'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  // Reconnection logic
  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    
    _reconnectTimer?.cancel();
    
    // Exponential backoff with jitter
    final backoffSeconds = (2 * _connectionAttempts).clamp(1, 30);
    final jitter = (backoffSeconds * 0.1).round();
    final delay = Duration(seconds: backoffSeconds + jitter);
    
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && !_isConnected) {
        _connect();
      }
    });
    
    if (kDebugMode) {
      debugPrint('Scheduling reconnect in ${delay.inSeconds} seconds');
    }
  }

  // Event listener management
  void on(String event, Function(Map<String, dynamic>) callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }

  void off(String event, [Function(Map<String, dynamic>)? callback]) {
    if (_eventListeners.containsKey(event)) {
      if (callback != null) {
        _eventListeners[event]!.remove(callback);
      } else {
        _eventListeners[event]!.clear();
      }
    }
  }

  void _notifyListeners(String event, Map<String, dynamic> data) {
    if (_eventListeners.containsKey(event)) {
      for (final listener in _eventListeners[event]!) {
        try {
          listener(data);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error in event listener: $e');
          }
        }
      }
    }
  }

  // Delivery-specific functionality
  
  // Accept delivery assignment
  Future<void> acceptDelivery({
    required String deliveryId,
    required String orderId,
    String? estimatedTime,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage({
      'type': 'accept_delivery',
      'delivery_id': deliveryId,
      'order_id': orderId,
      'estimated_time': estimatedTime,
      'metadata': metadata,
    });
  }

  // Reject delivery assignment
  Future<void> rejectDelivery({
    required String deliveryId,
    required String reason,
    String? notes,
  }) async {
    await _sendMessage({
      'type': 'reject_delivery',
      'delivery_id': deliveryId,
      'reason': reason,
      'notes': notes,
    });
  }

  // Update delivery status
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage({
      'type': 'delivery_status_update',
      'delivery_id': deliveryId,
      'status': status,
      'notes': notes,
      'metadata': metadata,
    });
  }

  // Update current location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    _currentLocation = {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy ?? 0.0,
      'speed': speed ?? 0.0,
      'heading': heading ?? 0.0,
    };

    if (_isConnected) {
      await _sendMessage({
        'type': 'location_update',
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
      });
    }
  }

  // Start location sharing
  Future<void> startLocationSharing() async {
    _locationSharingEnabled = true;
    if (_isConnected) {
      _startLocationUpdates();
      await _sendMessage({
        'type': 'start_location_sharing',
        'enabled': true,
      });
    }
  }

  // Stop location sharing
  Future<void> stopLocationSharing() async {
    _locationSharingEnabled = false;
    _locationUpdateTimer?.cancel();
    
    if (_isConnected) {
      await _sendMessage({
        'type': 'stop_location_sharing',
        'enabled': false,
      });
    }
  }

  // Request route optimization
  Future<void> requestRouteOptimization({
    required List<String> deliveryIds,
    String? startLocation,
    Map<String, dynamic>? preferences,
  }) async {
    await _sendMessage({
      'type': 'request_route_optimization',
      'delivery_ids': deliveryIds,
      'start_location': startLocation,
      'preferences': preferences,
    });
  }

  // Report traffic issue
  Future<void> reportTrafficIssue({
    required String issueType,
    required double latitude,
    required double longitude,
    String? description,
    String? severity,
  }) async {
    await _sendMessage({
      'type': 'report_traffic_issue',
      'issue_type': issueType,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'severity': severity ?? 'medium',
    });
  }

  // Send customer message
  Future<void> sendCustomerMessage({
    required String customerId,
    required String deliveryId,
    required String message,
    String? messageType,
  }) async {
    await _sendMessage({
      'type': 'send_customer_message',
      'customer_id': customerId,
      'delivery_id': deliveryId,
      'message': message,
      'message_type': messageType ?? 'text',
    });
  }

  // Request customer contact
  Future<void> requestCustomerContact({
    required String customerId,
    required String deliveryId,
    required String contactType, // 'call', 'message'
    String? reason,
  }) async {
    await _sendMessage({
      'type': 'request_customer_contact',
      'customer_id': customerId,
      'delivery_id': deliveryId,
      'contact_type': contactType,
      'reason': reason,
    });
  }

  // Mark delivery as complete
  Future<void> completeDelivery({
    required String deliveryId,
    required String confirmationCode,
    String? customerSignature,
    String? deliveryPhoto,
    String? notes,
  }) async {
    await _sendMessage({
      'type': 'complete_delivery',
      'delivery_id': deliveryId,
      'confirmation_code': confirmationCode,
      'customer_signature': customerSignature,
      'delivery_photo': deliveryPhoto,
      'notes': notes,
      'completion_time': DateTime.now().toIso8601String(),
    });
  }

  // Report delivery issue
  Future<void> reportDeliveryIssue({
    required String deliveryId,
    required String issueType,
    required String description,
    String? severity,
    List<String>? photos,
  }) async {
    await _sendMessage({
      'type': 'report_delivery_issue',
      'delivery_id': deliveryId,
      'issue_type': issueType,
      'description': description,
      'severity': severity ?? 'medium',
      'photos': photos,
    });
  }

  // Update availability status
  Future<void> updateAvailabilityStatus({
    required bool isAvailable,
    String? reason,
    DateTime? availableUntil,
  }) async {
    await _sendMessage({
      'type': 'update_availability',
      'is_available': isAvailable,
      'reason': reason,
      'available_until': availableUntil?.toIso8601String(),
    });
  }

  // Emergency alert
  Future<void> sendEmergencyAlert({
    required String alertType,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    await _sendMessage({
      'type': 'emergency_alert',
      'alert_type': alertType,
      'description': description,
      'latitude': latitude ?? _currentLocation?['latitude'],
      'longitude': longitude ?? _currentLocation?['longitude'],
      'urgent': true,
    });
  }

  // Chat functionality
  Future<void> joinChatRoom(String chatId) async {
    await _sendMessage({
      'type': 'join_chat',
      'chat_id': chatId,
      'participant_type': 'delivery_person',
    });
    _subscriptions.add('chat_$chatId');
  }

  Future<void> leaveChatRoom(String chatId) async {
    await _sendMessage({
      'type': 'leave_chat',
      'chat_id': chatId,
      'participant_type': 'delivery_person',
    });
    _subscriptions.remove('chat_$chatId');
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String message,
    required String senderId,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage({
      'type': 'chat_message',
      'chat_id': chatId,
      'message': message,
      'sender_id': senderId,
      'sender_type': 'delivery_person',
      'message_type': messageType ?? 'text',
      'metadata': metadata,
    });
  }

  // Performance metrics
  Future<void> updatePerformanceMetrics({
    required Map<String, dynamic> metrics,
  }) async {
    await _sendMessage({
      'type': 'performance_metrics',
      'metrics': metrics,
    });
  }

  // Vehicle information
  Future<void> updateVehicleInfo({
    required String vehicleType,
    String? vehiclePlate,
    String? vehicleColor,
    String? vehicleModel,
  }) async {
    await _sendMessage({
      'type': 'update_vehicle_info',
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'vehicle_color': vehicleColor,
      'vehicle_model': vehicleModel,
    });
  }

  // Subscribe to delivery zone
  Future<void> subscribeToDeliveryZone(String zoneId) async {
    await _sendMessage({
      'type': 'subscribe',
      'channel': 'delivery_zone_$zoneId',
      'zone_id': zoneId,
    });
    _subscriptions.add('delivery_zone_$zoneId');
  }

  // Unsubscribe from delivery zone
  Future<void> unsubscribeFromDeliveryZone(String zoneId) async {
    await _sendMessage({
      'type': 'unsubscribe',
      'channel': 'delivery_zone_$zoneId',
      'zone_id': zoneId,
    });
    _subscriptions.remove('delivery_zone_$zoneId');
  }

  // Subscribe to system updates
  Future<void> subscribeToSystemUpdates() async {
    await _sendMessage({
      'type': 'subscribe',
      'channel': 'system_updates',
    });
    _subscriptions.add('system_updates');
  }

  // Connection management
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _heartbeatTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_isConnected && _channel != null) {
      await _channel!.sink.close(status.goingAway);
    }
    
    _isConnected = false;
    
    if (kDebugMode) {
      debugPrint('WebSocket manually disconnected (Delivery App)');
    }
  }

  Future<void> reconnect() async {
    await disconnect();
    _shouldReconnect = true;
    _connectionAttempts = 0;
    await _connect();
  }

  Future<void> reset() async {
    _subscriptions.clear();
    _messageQueue.clear();
    await reconnect();
  }

  void setAutoReconnect(bool enabled) {
    _shouldReconnect = enabled;
    if (!enabled) {
      _reconnectTimer?.cancel();
      _locationUpdateTimer?.cancel();
    }
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'is_connected': _isConnected,
      'connection_attempts': _connectionAttempts,
      'last_connected': _lastConnected?.toIso8601String(),
      'messages_sent': _messagesSent,
      'messages_received': _messagesReceived,
      'active_subscriptions': _subscriptions.length,
      'queued_messages': _messageQueue.length,
      'location_sharing_enabled': _locationSharingEnabled,
      'current_location': _currentLocation,
      'delivery_person_id': _deliveryPersonId,
    };
  }

  // Cleanup
  void dispose() {
    disconnect();
    _eventListeners.clear();
    _subscriptions.clear();
    _messageQueue.clear();
  }
}