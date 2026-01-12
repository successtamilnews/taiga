import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration reconnectInterval = Duration(seconds: 5);

  String? _wsUrl;
  String? _authToken;
  Map<String, List<Function(dynamic)>> _eventListeners = {};

  // Connection status
  bool get isConnected => _isConnected;

  // Initialize WebSocket connection
  Future<void> initialize({
    required String wsUrl,
    required String authToken,
  }) async {
    _wsUrl = wsUrl;
    _authToken = authToken;
    await connect();
  }

  // Connect to WebSocket
  Future<void> connect() async {
    if (_isConnected || _wsUrl == null || _authToken == null) return;

    try {
      debugPrint('Connecting to WebSocket: $_wsUrl');
      
      _channel = WebSocketChannel.connect(
        Uri.parse('$_wsUrl?token=$_authToken'),
      );

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnection,
        onError: _handleError,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      
      debugPrint('WebSocket connected successfully');
      
      // Send authentication message
      await _authenticate();
      
      // Start heartbeat
      _startHeartbeat();
      
      // Notify connection status
      _notifyListeners('connection_status', {'connected': true});

    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  // Disconnect WebSocket
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _stopHeartbeat();
    _stopReconnectTimer();

    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    _isConnected = false;
    debugPrint('WebSocket disconnected');
    
    _notifyListeners('connection_status', {'connected': false});
  }

  // Send message
  Future<void> send(String event, Map<String, dynamic> data) async {
    if (!_isConnected || _channel == null) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }

    final message = {
      'event': event,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(json.encode(message));
      debugPrint('Sent WebSocket message: $event');
    } catch (e) {
      debugPrint('Error sending WebSocket message: $e');
    }
  }

  // Subscribe to event
  void on(String event, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }

  // Unsubscribe from event
  void off(String event, [Function(dynamic)? callback]) {
    if (!_eventListeners.containsKey(event)) return;

    if (callback != null) {
      _eventListeners[event]!.remove(callback);
    } else {
      _eventListeners[event]!.clear();
    }

    if (_eventListeners[event]!.isEmpty) {
      _eventListeners.remove(event);
    }
  }

  // Join room
  Future<void> joinRoom(String room) async {
    await send('join_room', {'room': room});
  }

  // Leave room
  Future<void> leaveRoom(String room) async {
    await send('leave_room', {'room': room});
  }

  // Real-time order tracking
  Future<void> trackOrder(String orderId) async {
    await joinRoom('order_$orderId');
  }

  Future<void> stopTrackingOrder(String orderId) async {
    await leaveRoom('order_$orderId');
  }

  // Real-time inventory updates
  Future<void> subscribeToInventoryUpdates(String productId) async {
    await joinRoom('inventory_$productId');
  }

  Future<void> unsubscribeFromInventoryUpdates(String productId) async {
    await leaveRoom('inventory_$productId');
  }

  // Real-time chat
  Future<void> joinChatRoom(String chatId) async {
    await joinRoom('chat_$chatId');
  }

  Future<void> leaveChatRoom(String chatId) async {
    await leaveRoom('chat_$chatId');
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String message,
    required String senderId,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    await send('chat_message', {
      'chat_id': chatId,
      'message': message,
      'sender_id': senderId,
      'message_type': messageType ?? 'text',
      'metadata': metadata,
    });
  }

  // Real-time delivery tracking
  Future<void> trackDelivery(String deliveryId) async {
    await joinRoom('delivery_$deliveryId');
  }

  Future<void> stopTrackingDelivery(String deliveryId) async {
    await leaveRoom('delivery_$deliveryId');
  }

  Future<void> updateDeliveryLocation({
    required String deliveryId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    await send('delivery_location_update', {
      'delivery_id': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
  }

  // Real-time seller updates
  Future<void> subscribeToSellerUpdates(String sellerId) async {
    await joinRoom('seller_$sellerId');
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    await send('order_status_update', {
      'order_id': orderId,
      'status': status,
      'notes': notes,
    });
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final event = data['event'] as String?;
      final payload = data['data'];

      if (event != null) {
        debugPrint('Received WebSocket event: $event');
        _notifyListeners(event, payload);
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  // Handle disconnection
  void _handleDisconnection() {
    debugPrint('WebSocket disconnected');
    _isConnected = false;
    _stopHeartbeat();
    
    _notifyListeners('connection_status', {'connected': false});
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  // Handle errors
  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  // Authenticate connection
  Future<void> _authenticate() async {
    await send('authenticate', {
      'token': _authToken,
      'platform': defaultTargetPlatform.name,
    });
  }

  // Start heartbeat
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
      if (_isConnected) {
        send('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached or reconnection disabled');
      return;
    }

    _stopReconnectTimer();
    
    final delay = Duration(
      seconds: reconnectInterval.inSeconds * (_reconnectAttempts + 1),
    );
    
    debugPrint('Scheduling reconnection in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1})');
    
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  // Stop reconnection timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Notify event listeners
  void _notifyListeners(String event, dynamic data) {
    if (_eventListeners.containsKey(event)) {
      for (final callback in _eventListeners[event]!) {
        try {
          callback(data);
        } catch (e) {
          debugPrint('Error in WebSocket event callback: $e');
        }
      }
    }
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'connected': _isConnected,
      'reconnect_attempts': _reconnectAttempts,
      'active_listeners': _eventListeners.length,
      'should_reconnect': _shouldReconnect,
    };
  }

  // Enable/disable auto-reconnection
  void setAutoReconnect(bool enabled) {
    _shouldReconnect = enabled;
    if (!enabled) {
      _stopReconnectTimer();
    }
  }

  // Reset connection
  Future<void> reset() async {
    await disconnect();
    _reconnectAttempts = 0;
    _shouldReconnect = true;
    await connect();
  }

  // Dispose
  void dispose() {
    disconnect();
    _eventListeners.clear();
  }
}

// WebSocket event types
class WebSocketEvents {
  static const String connectionStatus = 'connection_status';
  static const String orderUpdate = 'order_update';
  static const String deliveryUpdate = 'delivery_update';
  static const String inventoryUpdate = 'inventory_update';
  static const String chatMessage = 'chat_message';
  static const String deliveryLocation = 'delivery_location_update';
  static const String newOrder = 'new_order';
  static const String orderCanceled = 'order_canceled';
  static const String paymentUpdate = 'payment_update';
  static const String sellerNotification = 'seller_notification';
  static const String deliveryAssigned = 'delivery_assigned';
  static const String userOnlineStatus = 'user_online_status';
  static const String systemMaintenance = 'system_maintenance';
}