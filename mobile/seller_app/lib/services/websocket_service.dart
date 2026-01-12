import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'dart:async';

class WebSocketEvents {
  static const String connectionStatus = 'connection_status';
  static const String newOrder = 'new_order';
  static const String orderUpdate = 'order_update';
  static const String inventoryUpdate = 'inventory_update';
  static const String chatMessage = 'chat_message';
  static const String paymentUpdate = 'payment_update';
  static const String sellerUpdate = 'seller_update';
  static const String customerQuery = 'customer_query';
  static const String systemMaintenance = 'system_maintenance';
  static const String performanceMetrics = 'performance_metrics';
}

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  String? _wsUrl;
  String? _authToken;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
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

  // Getters
  bool get isConnected => _isConnected;
  int get connectionAttempts => _connectionAttempts;
  DateTime? get lastConnected => _lastConnected;

  // Initialize WebSocket connection
  Future<void> initialize({
    required String wsUrl,
    required String authToken,
  }) async {
    _wsUrl = wsUrl;
    _authToken = authToken;
    
    await _connect();
  }

  // Connect to WebSocket
  Future<void> _connect() async {
    if (_isConnected || _wsUrl == null) return;

    try {
      _connectionAttempts++;
      
      final uri = Uri.parse('$_wsUrl?token=$_authToken&type=seller');
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
      
      // Notify connection status
      _notifyListeners(WebSocketEvents.connectionStatus, {
        'connected': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        debugPrint('WebSocket connected (Seller App)');
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
        debugPrint('WebSocket message received (Seller): $eventType');
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
    
    _notifyListeners(WebSocketEvents.connectionStatus, {
      'connected': false,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (kDebugMode) {
      debugPrint('WebSocket disconnected (Seller App)');
    }
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  // Send message
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = jsonEncode(message);
        _channel!.sink.add(jsonMessage);
        _messagesSent++;
        
        if (kDebugMode) {
          debugPrint('WebSocket message sent (Seller): ${message['type']}');
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

  // Seller-specific functionality
  
  // Subscribe to seller updates
  Future<void> subscribeToSellerUpdates(String sellerId) async {
    await _sendMessage({
      'type': 'subscribe',
      'channel': 'seller_$sellerId',
      'seller_id': sellerId,
    });
    _subscriptions.add('seller_$sellerId');
  }

  // Subscribe to new orders
  Future<void> subscribeToNewOrders(String sellerId) async {
    await _sendMessage({
      'type': 'subscribe',
      'channel': 'seller_orders_$sellerId',
      'seller_id': sellerId,
    });
    _subscriptions.add('seller_orders_$sellerId');
  }

  // Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage({
      'type': 'order_status_update',
      'order_id': orderId,
      'status': status,
      'notes': notes,
      'metadata': metadata,
      'updated_by': 'seller',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Update inventory
  Future<void> updateInventory({
    required String productId,
    required int quantity,
    required bool isAvailable,
    double? price,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage({
      'type': 'inventory_update',
      'product_id': productId,
      'quantity': quantity,
      'is_available': isAvailable,
      'price': price,
      'metadata': metadata,
      'updated_by': 'seller',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send message to customer
  Future<void> sendCustomerMessage({
    required String customerId,
    required String orderId,
    required String message,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage({
      'type': 'customer_message',
      'customer_id': customerId,
      'order_id': orderId,
      'message': message,
      'message_type': messageType ?? 'text',
      'metadata': metadata,
      'sender_type': 'seller',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Join chat room (for customer support)
  Future<void> joinChatRoom(String chatId) async {
    await _sendMessage({
      'type': 'join_chat',
      'chat_id': chatId,
      'participant_type': 'seller',
    });
    _subscriptions.add('chat_$chatId');
  }

  // Leave chat room
  Future<void> leaveChatRoom(String chatId) async {
    await _sendMessage({
      'type': 'leave_chat',
      'chat_id': chatId,
      'participant_type': 'seller',
    });
    _subscriptions.remove('chat_$chatId');
  }

  // Send chat message
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
      'sender_type': 'seller',
      'message_type': messageType ?? 'text',
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Update seller availability
  Future<void> updateSellerAvailability({
    required String sellerId,
    required bool isAvailable,
    String? availabilityNote,
  }) async {
    await _sendMessage({
      'type': 'seller_availability_update',
      'seller_id': sellerId,
      'is_available': isAvailable,
      'availability_note': availabilityNote,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Broadcast seller announcement
  Future<void> broadcastAnnouncement({
    required String sellerId,
    required String title,
    required String message,
    String? targetAudience, // 'customers', 'all'
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage({
      'type': 'seller_announcement',
      'seller_id': sellerId,
      'title': title,
      'message': message,
      'target_audience': targetAudience ?? 'customers',
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Request performance metrics
  Future<void> requestPerformanceMetrics({
    required String sellerId,
    String? timeRange, // 'today', 'week', 'month'
    List<String>? metrics,
  }) async {
    await _sendMessage({
      'type': 'request_performance_metrics',
      'seller_id': sellerId,
      'time_range': timeRange ?? 'today',
      'metrics': metrics ?? ['orders', 'revenue', 'inventory'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Subscribe to system announcements
  Future<void> subscribeToSystemAnnouncements() async {
    await _sendMessage({
      'type': 'subscribe',
      'channel': 'system_announcements',
    });
    _subscriptions.add('system_announcements');
  }

  // Unsubscribe from channel
  Future<void> unsubscribeFromChannel(String channel) async {
    await _sendMessage({
      'type': 'unsubscribe',
      'channel': channel,
    });
    _subscriptions.remove(channel);
  }

  // Connection management
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_isConnected && _channel != null) {
      await _channel!.sink.close(status.goingAway);
    }
    
    _isConnected = false;
    
    if (kDebugMode) {
      debugPrint('WebSocket manually disconnected (Seller App)');
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