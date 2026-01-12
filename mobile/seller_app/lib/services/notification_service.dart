import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio();

  bool _isInitialized = false;
  String? _fcmToken;
  String? _baseUrl;
  String? _authToken;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _newOrderNotifications = true;
  bool _orderUpdateNotifications = true;
  bool _inventoryNotifications = true;
  bool _promotionalNotifications = false;
  bool _paymentNotifications = true;
  bool _systemNotifications = true;

  // Notification history
  final List<NotificationMessage> _notificationHistory = [];
  int _unreadCount = 0;

  // Event callbacks
  Function(NotificationMessage)? onNotificationReceived;
  Function(NotificationMessage)? onNotificationTapped;
  Function(String)? onTokenRefresh;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;
  List<NotificationMessage> get notificationHistory => List.unmodifiable(_notificationHistory);
  int get unreadCount => _unreadCount;
  
  // Notification settings getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get newOrderNotifications => _newOrderNotifications;
  bool get orderUpdateNotifications => _orderUpdateNotifications;
  bool get inventoryNotifications => _inventoryNotifications;
  bool get promotionalNotifications => _promotionalNotifications;
  bool get paymentNotifications => _paymentNotifications;
  bool get systemNotifications => _systemNotifications;

  // Initialize notification service
  Future<void> initialize({
    required String baseUrl,
    String? authToken,
  }) async {
    if (_isInitialized) return;

    _baseUrl = baseUrl;
    _authToken = authToken;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();

    // Load settings and history
    await _loadSettings();
    await _loadNotificationHistory();

    // Setup Dio interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('NotificationService initialized for seller app');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannels();
    }
  }

  // Create Android notification channels
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'new_orders',
        'New Orders',
        description: 'Notifications for new orders received',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Notifications for order status updates',
        importance: Importance.defaultImportance,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'inventory_alerts',
        'Inventory Alerts',
        description: 'Notifications for inventory alerts',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'payments',
        'Payment Notifications',
        description: 'Notifications for payment updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'promotions',
        'Promotional Notifications',
        description: 'Notifications for promotions and marketing',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'system',
        'System Notifications',
        description: 'Important system notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    await _requestPermission();

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    
    if (kDebugMode && _fcmToken != null) {
      debugPrint('FCM Token (Seller App): $_fcmToken');
    }

    // Setup message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      if (onTokenRefresh != null) {
        onTokenRefresh!(token);
      }
      _updateTokenOnServer(token);
    });

    // Handle initial message (app opened from notification)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Subscribe to seller topics
    await subscribeToSellerTopics();
  }

  // Request notification permission
  Future<bool> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (kDebugMode) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    }

    return isAuthorized;
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Foreground message received: ${message.messageId}');
    }

    final notificationMessage = NotificationMessage.fromFirebaseMessage(message);
    
    // Add to history
    _addNotificationToHistory(notificationMessage);

    // Show local notification if enabled
    if (_shouldShowNotification(notificationMessage)) {
      await _showLocalNotification(notificationMessage);
    }

    // Trigger callback
    if (onNotificationReceived != null) {
      onNotificationReceived!(notificationMessage);
    }
  }

  // Handle background message
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Background message received: ${message.messageId}');
    }
    // Handle background message logic here
  }

  // Handle message opened app
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Message opened app: ${message.messageId}');
    }

    final notificationMessage = NotificationMessage.fromFirebaseMessage(message);
    
    // Mark as read
    markNotificationAsRead(notificationMessage.id);

    // Trigger callback
    if (onNotificationTapped != null) {
      onNotificationTapped!(notificationMessage);
    }
  }

  // Handle local notification tapped
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Local notification tapped: ${response.id}');
    }

    // Find notification in history
    final notification = _notificationHistory
        .where((n) => n.id == response.id.toString())
        .firstOrNull;

    if (notification != null) {
      markNotificationAsRead(notification.id);
      
      if (onNotificationTapped != null) {
        onNotificationTapped!(notification);
      }
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(NotificationMessage message) async {
    final channelId = _getChannelIdForType(message.type);
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelNameForType(message.type),
      channelDescription: _getChannelDescriptionForType(message.type),
      importance: _getImportanceForType(message.type),
      priority: Priority.high,
      enableVibration: _vibrationEnabled,
      playSound: _soundEnabled,
      icon: '@mipmap/ic_launcher',
      largeIcon: message.imageUrl != null ? FilePathAndroidBitmap(message.imageUrl!) : null,
      styleInformation: message.body.length > 50
          ? BigTextStyleInformation(message.body)
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.id.hashCode,
      message.title,
      message.body,
      details,
      payload: message.data['action'],
    );
  }

  // Notification type helpers
  String _getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return 'new_orders';
      case NotificationType.orderUpdate:
        return 'order_updates';
      case NotificationType.inventory:
        return 'inventory_alerts';
      case NotificationType.payment:
        return 'payments';
      case NotificationType.promotional:
        return 'promotions';
      case NotificationType.system:
        return 'system';
    }
  }

  String _getChannelNameForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return 'New Orders';
      case NotificationType.orderUpdate:
        return 'Order Updates';
      case NotificationType.inventory:
        return 'Inventory Alerts';
      case NotificationType.payment:
        return 'Payment Notifications';
      case NotificationType.promotional:
        return 'Promotional Notifications';
      case NotificationType.system:
        return 'System Notifications';
    }
  }

  String _getChannelDescriptionForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return 'Notifications for new orders received';
      case NotificationType.orderUpdate:
        return 'Notifications for order status updates';
      case NotificationType.inventory:
        return 'Notifications for inventory alerts';
      case NotificationType.payment:
        return 'Notifications for payment updates';
      case NotificationType.promotional:
        return 'Notifications for promotions and marketing';
      case NotificationType.system:
        return 'Important system notifications';
    }
  }

  Importance _getImportanceForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.payment:
      case NotificationType.system:
        return Importance.high;
      case NotificationType.orderUpdate:
      case NotificationType.inventory:
        return Importance.defaultImportance;
      case NotificationType.promotional:
        return Importance.low;
    }
  }

  // Check if notification should be shown
  bool _shouldShowNotification(NotificationMessage message) {
    if (!_notificationsEnabled) return false;

    switch (message.type) {
      case NotificationType.newOrder:
        return _newOrderNotifications;
      case NotificationType.orderUpdate:
        return _orderUpdateNotifications;
      case NotificationType.inventory:
        return _inventoryNotifications;
      case NotificationType.payment:
        return _paymentNotifications;
      case NotificationType.promotional:
        return _promotionalNotifications;
      case NotificationType.system:
        return _systemNotifications;
    }
  }

  // Topic subscriptions for sellers
  Future<void> subscribeToSellerTopics() async {
    await _firebaseMessaging.subscribeToTopic('sellers');
    await _firebaseMessaging.subscribeToTopic('system_announcements');
    
    if (kDebugMode) {
      debugPrint('Subscribed to seller topics');
    }
  }

  Future<void> subscribeToSellerSpecificTopic(String sellerId) async {
    await _firebaseMessaging.subscribeToTopic('seller_$sellerId');
    
    if (kDebugMode) {
      debugPrint('Subscribed to seller_$sellerId topic');
    }
  }

  Future<void> unsubscribeFromSellerSpecificTopic(String sellerId) async {
    await _firebaseMessaging.unsubscribeFromTopic('seller_$sellerId');
    
    if (kDebugMode) {
      debugPrint('Unsubscribed from seller_$sellerId topic');
    }
  }

  // Notification history management
  void _addNotificationToHistory(NotificationMessage message) {
    _notificationHistory.insert(0, message);
    _unreadCount++;
    
    // Limit history size
    if (_notificationHistory.length > 1000) {
      _notificationHistory.removeLast();
    }
    
    _saveNotificationHistory();
  }

  void markNotificationAsRead(String notificationId) {
    final index = _notificationHistory.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notificationHistory[index].isRead) {
      _notificationHistory[index] = _notificationHistory[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notificationHistory.length);
      _saveNotificationHistory();
    }
  }

  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notificationHistory.length; i++) {
      if (!_notificationHistory[i].isRead) {
        _notificationHistory[i] = _notificationHistory[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    _saveNotificationHistory();
  }

  void clearNotificationHistory() {
    _notificationHistory.clear();
    _unreadCount = 0;
    _saveNotificationHistory();
  }

  // Settings management
  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? newOrderNotifications,
    bool? orderUpdateNotifications,
    bool? inventoryNotifications,
    bool? promotionalNotifications,
    bool? paymentNotifications,
    bool? systemNotifications,
  }) async {
    if (notificationsEnabled != null) _notificationsEnabled = notificationsEnabled;
    if (soundEnabled != null) _soundEnabled = soundEnabled;
    if (vibrationEnabled != null) _vibrationEnabled = vibrationEnabled;
    if (newOrderNotifications != null) _newOrderNotifications = newOrderNotifications;
    if (orderUpdateNotifications != null) _orderUpdateNotifications = orderUpdateNotifications;
    if (inventoryNotifications != null) _inventoryNotifications = inventoryNotifications;
    if (promotionalNotifications != null) _promotionalNotifications = promotionalNotifications;
    if (paymentNotifications != null) _paymentNotifications = paymentNotifications;
    if (systemNotifications != null) _systemNotifications = systemNotifications;

    await _saveSettings();
    await _updateServerSettings();

    if (kDebugMode) {
      debugPrint('Notification settings updated');
    }
  }

  // Server communication
  Future<void> _updateTokenOnServer(String token) async {
    if (_baseUrl == null) return;

    try {
      await _dio.post('$_baseUrl/api/notifications/token', data: {
        'fcm_token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'app_type': 'seller',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update token on server: $e');
      }
    }
  }

  Future<void> _updateServerSettings() async {
    if (_baseUrl == null) return;

    try {
      await _dio.post('$_baseUrl/api/notifications/settings', data: {
        'notifications_enabled': _notificationsEnabled,
        'sound_enabled': _soundEnabled,
        'vibration_enabled': _vibrationEnabled,
        'new_order_notifications': _newOrderNotifications,
        'order_update_notifications': _orderUpdateNotifications,
        'inventory_notifications': _inventoryNotifications,
        'promotional_notifications': _promotionalNotifications,
        'payment_notifications': _paymentNotifications,
        'system_notifications': _systemNotifications,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update settings on server: $e');
      }
    }
  }

  // Persistence
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('new_order_notifications', _newOrderNotifications);
    await prefs.setBool('order_update_notifications', _orderUpdateNotifications);
    await prefs.setBool('inventory_notifications', _inventoryNotifications);
    await prefs.setBool('promotional_notifications', _promotionalNotifications);
    await prefs.setBool('payment_notifications', _paymentNotifications);
    await prefs.setBool('system_notifications', _systemNotifications);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _newOrderNotifications = prefs.getBool('new_order_notifications') ?? true;
    _orderUpdateNotifications = prefs.getBool('order_update_notifications') ?? true;
    _inventoryNotifications = prefs.getBool('inventory_notifications') ?? true;
    _promotionalNotifications = prefs.getBool('promotional_notifications') ?? false;
    _paymentNotifications = prefs.getBool('payment_notifications') ?? true;
    _systemNotifications = prefs.getBool('system_notifications') ?? true;
  }

  Future<void> _saveNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _notificationHistory.map((n) => n.toJson()).toList();
    await prefs.setString('notification_history_seller', jsonEncode(historyJson));
    await prefs.setInt('unread_count_seller', _unreadCount);
  }

  Future<void> _loadNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('notification_history_seller');
    _unreadCount = prefs.getInt('unread_count_seller') ?? 0;
    
    if (historyString != null) {
      final List<dynamic> historyJson = jsonDecode(historyString);
      _notificationHistory.clear();
      _notificationHistory.addAll(
        historyJson.map((json) => NotificationMessage.fromJson(json)).toList(),
      );
    }
  }

  // Public API methods
  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> sendTestNotification() async {
    final testMessage = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Test Notification',
      body: 'This is a test notification for the seller app',
      type: NotificationType.system,
      timestamp: DateTime.now(),
      data: {},
    );

    await _showLocalNotification(testMessage);
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cleanup
  void dispose() {
    // Any cleanup if needed
  }
}

// Notification message model
enum NotificationType {
  newOrder,
  orderUpdate,
  inventory,
  payment,
  promotional,
  system,
}

class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final bool isRead;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.data,
    this.imageUrl,
    this.isRead = false,
  });

  factory NotificationMessage.fromFirebaseMessage(RemoteMessage message) {
    return NotificationMessage(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      timestamp: DateTime.now(),
      data: message.data,
      imageUrl: message.notification?.android?.imageUrl,
    );
  }

  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'new_order':
        return NotificationType.newOrder;
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'inventory':
        return NotificationType.inventory;
      case 'payment':
        return NotificationType.payment;
      case 'promotional':
        return NotificationType.promotional;
      default:
        return NotificationType.system;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'image_url': imageUrl,
      'is_read': isRead,
    };
  }

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data']),
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
    );
  }

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    String? imageUrl,
    bool? isRead,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
    );
  }
}