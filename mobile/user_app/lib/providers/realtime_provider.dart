import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';

class RealTimeProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();

  // Connection state
  bool _isConnected = false;
  bool _isInitialized = false;
  String? _error;

  // Real-time data
  Map<String, dynamic> _orderUpdates = {};
  Map<String, dynamic> _deliveryLocations = {};
  Map<String, dynamic> _inventoryUpdates = {};
  List<ChatMessage> _chatMessages = [];
  Map<String, bool> _userOnlineStatus = {};

  // Getters
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  Map<String, dynamic> get orderUpdates => _orderUpdates;
  Map<String, dynamic> get deliveryLocations => _deliveryLocations;
  Map<String, dynamic> get inventoryUpdates => _inventoryUpdates;
  List<ChatMessage> get chatMessages => _chatMessages;
  Map<String, bool> get userOnlineStatus => _userOnlineStatus;

  // Initialize real-time connection
  Future<void> initialize({
    required String wsUrl,
    required String authToken,
  }) async {
    if (_isInitialized) return;

    try {
      await _webSocketService.initialize(
        wsUrl: wsUrl,
        authToken: authToken,
      );

      _setupEventListeners();
      _isInitialized = true;
      
    } catch (e) {
      _error = 'Failed to initialize real-time connection: $e';
      debugPrint(_error);
    }
    
    notifyListeners();
  }

  // Setup event listeners
  void _setupEventListeners() {
    // Connection status
    _webSocketService.on(WebSocketEvents.connectionStatus, (data) {
      _isConnected = data['connected'] ?? false;
      if (!_isConnected) {
        _error = 'Connection lost';
      } else {
        _error = null;
      }
      notifyListeners();
    });

    // Order updates
    _webSocketService.on(WebSocketEvents.orderUpdate, (data) {
      final orderId = data['order_id'] as String?;
      if (orderId != null) {
        _orderUpdates[orderId] = data;
        notifyListeners();
      }
    });

    // New orders (for sellers)
    _webSocketService.on(WebSocketEvents.newOrder, (data) {
      final orderId = data['order_id'] as String?;
      if (orderId != null) {
        _orderUpdates[orderId] = {
          ...data,
          'is_new': true,
        };
        notifyListeners();
      }
    });

    // Delivery updates
    _webSocketService.on(WebSocketEvents.deliveryUpdate, (data) {
      final orderId = data['order_id'] as String?;
      if (orderId != null) {
        _orderUpdates[orderId] = {
          ..._orderUpdates[orderId] ?? {},
          'delivery_status': data['delivery_status'],
          'delivery_location': data['location'],
          'estimated_arrival': data['estimated_arrival'],
        };
        notifyListeners();
      }
    });

    // Delivery location updates
    _webSocketService.on(WebSocketEvents.deliveryLocation, (data) {
      final deliveryId = data['delivery_id'] as String?;
      if (deliveryId != null) {
        _deliveryLocations[deliveryId] = {
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'address': data['address'],
          'timestamp': DateTime.now().toIso8601String(),
        };
        notifyListeners();
      }
    });

    // Inventory updates
    _webSocketService.on(WebSocketEvents.inventoryUpdate, (data) {
      final productId = data['product_id'] as String?;
      if (productId != null) {
        _inventoryUpdates[productId] = {
          'stock_quantity': data['stock_quantity'],
          'is_available': data['is_available'],
          'price': data['price'],
          'updated_at': DateTime.now().toIso8601String(),
        };
        notifyListeners();
      }
    });

    // Chat messages
    _webSocketService.on(WebSocketEvents.chatMessage, (data) {
      final message = ChatMessage.fromJson(data);
      _chatMessages.add(message);
      notifyListeners();
    });

    // User online status
    _webSocketService.on(WebSocketEvents.userOnlineStatus, (data) {
      final userId = data['user_id'] as String?;
      final isOnline = data['is_online'] as bool?;
      if (userId != null && isOnline != null) {
        _userOnlineStatus[userId] = isOnline;
        notifyListeners();
      }
    });

    // Payment updates
    _webSocketService.on(WebSocketEvents.paymentUpdate, (data) {
      final orderId = data['order_id'] as String?;
      if (orderId != null) {
        _orderUpdates[orderId] = {
          ..._orderUpdates[orderId] ?? {},
          'payment_status': data['payment_status'],
          'payment_method': data['payment_method'],
          'transaction_id': data['transaction_id'],
        };
        notifyListeners();
      }
    });

    // System maintenance
    _webSocketService.on(WebSocketEvents.systemMaintenance, (data) {
      _error = data['message'] ?? 'System maintenance in progress';
      notifyListeners();
    });
  }

  // Order tracking
  Future<void> trackOrder(String orderId) async {
    await _webSocketService.trackOrder(orderId);
  }

  Future<void> stopTrackingOrder(String orderId) async {
    await _webSocketService.stopTrackingOrder(orderId);
    _orderUpdates.remove(orderId);
    notifyListeners();
  }

  // Get order status
  Map<String, dynamic>? getOrderStatus(String orderId) {
    return _orderUpdates[orderId];
  }

  // Delivery tracking
  Future<void> trackDelivery(String deliveryId) async {
    await _webSocketService.trackDelivery(deliveryId);
  }

  Future<void> stopTrackingDelivery(String deliveryId) async {
    await _webSocketService.stopTrackingDelivery(deliveryId);
    _deliveryLocations.remove(deliveryId);
    notifyListeners();
  }

  // Update delivery location (for delivery personnel)
  Future<void> updateDeliveryLocation({
    required String deliveryId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    await _webSocketService.updateDeliveryLocation(
      deliveryId: deliveryId,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  // Get delivery location
  Map<String, dynamic>? getDeliveryLocation(String deliveryId) {
    return _deliveryLocations[deliveryId];
  }

  // Inventory management
  Future<void> subscribeToInventoryUpdates(String productId) async {
    await _webSocketService.subscribeToInventoryUpdates(productId);
  }

  Future<void> unsubscribeFromInventoryUpdates(String productId) async {
    await _webSocketService.unsubscribeFromInventoryUpdates(productId);
    _inventoryUpdates.remove(productId);
    notifyListeners();
  }

  // Get inventory status
  Map<String, dynamic>? getInventoryStatus(String productId) {
    return _inventoryUpdates[productId];
  }

  // Chat functionality
  Future<void> joinChatRoom(String chatId) async {
    await _webSocketService.joinChatRoom(chatId);
  }

  Future<void> leaveChatRoom(String chatId) async {
    await _webSocketService.leaveChatRoom(chatId);
    _chatMessages.removeWhere((msg) => msg.chatId == chatId);
    notifyListeners();
  }

  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String senderId,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    await _webSocketService.sendChatMessage(
      chatId: chatId,
      message: message,
      senderId: senderId,
      messageType: messageType,
      metadata: metadata,
    );
  }

  // Get chat messages for a specific chat
  List<ChatMessage> getChatMessages(String chatId) {
    return _chatMessages.where((msg) => msg.chatId == chatId).toList();
  }

  // Seller functionality
  Future<void> subscribeToSellerUpdates(String sellerId) async {
    await _webSocketService.subscribeToSellerUpdates(sellerId);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    await _webSocketService.updateOrderStatus(
      orderId: orderId,
      status: status,
      notes: notes,
    );
  }

  // User online status
  bool isUserOnline(String userId) {
    return _userOnlineStatus[userId] ?? false;
  }

  // Connection management
  Future<void> reconnect() async {
    await _webSocketService.reset();
  }

  Map<String, dynamic> getConnectionStats() {
    return _webSocketService.getConnectionStats();
  }

  void setAutoReconnect(bool enabled) {
    _webSocketService.setAutoReconnect(enabled);
  }

  // Clear data
  void clearOrderUpdate(String orderId) {
    _orderUpdates.remove(orderId);
    notifyListeners();
  }

  void clearChatMessages(String chatId) {
    _chatMessages.removeWhere((msg) => msg.chatId == chatId);
    notifyListeners();
  }

  void clearAllData() {
    _orderUpdates.clear();
    _deliveryLocations.clear();
    _inventoryUpdates.clear();
    _chatMessages.clear();
    _userOnlineStatus.clear();
    notifyListeners();
  }

  // Error handling
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}

// Chat message model
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.messageType,
    this.metadata,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}