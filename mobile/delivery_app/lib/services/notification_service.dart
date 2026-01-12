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

  // Delivery-specific notification settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _newDeliveryNotifications = true;
  bool _routeUpdateNotifications = true;
  bool _urgentDeliveryNotifications = true;
  bool _paymentNotifications = true;
  bool _trafficAlertNotifications = true;
  bool _customerMessageNotifications = true;
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
  
  // Delivery notification settings getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get newDeliveryNotifications => _newDeliveryNotifications;
  bool get routeUpdateNotifications => _routeUpdateNotifications;
  bool get urgentDeliveryNotifications => _urgentDeliveryNotifications;
  bool get paymentNotifications => _paymentNotifications;
  bool get trafficAlertNotifications => _trafficAlertNotifications;
  bool get customerMessageNotifications => _customerMessageNotifications;
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
      debugPrint('NotificationService initialized for delivery app');
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

  // Create Android notification channels for delivery-specific notifications
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'new_deliveries',
        'New Deliveries',
        description: 'Notifications for new delivery assignments',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('delivery_assigned'),
      ),
      AndroidNotificationChannel(
        'route_updates',
        'Route Updates',
        description: 'Notifications for route changes and optimizations',
        importance: Importance.high,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'urgent_deliveries',
        'Urgent Deliveries',
        description: 'Notifications for time-sensitive deliveries',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('urgent_delivery'),
      ),
      AndroidNotificationChannel(
        'traffic_alerts',
        'Traffic Alerts',
        description: 'Notifications for traffic conditions and route alerts',
        importance: Importance.defaultImportance,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'customer_messages',
        'Customer Messages',
        description: 'Notifications for customer communication',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'payments',
        'Payment Notifications',
        description: 'Notifications for payment updates and earnings',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'system',
        'System Notifications',
        description: 'Important system and policy notifications',
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
      debugPrint('FCM Token (Delivery App): $_fcmToken');
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

    // Subscribe to delivery topics
    await subscribeToDeliveryTopics();
  }

  // Request notification permission
  Future<bool> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true, // Important for delivery notifications
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

  // Show local notification with delivery-specific styling
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
      styleInformation: _getStyleInformation(message),
      category: AndroidNotificationCategory.transport,
      ongoing: message.type == DeliveryNotificationType.activeDelivery,
      autoCancel: message.type != DeliveryNotificationType.activeDelivery,
      actions: _getNotificationActions(message.type),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'DELIVERY_NOTIFICATION',
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

  // Get notification style based on type
  AndroidNotificationDetails _getStyleInformation(NotificationMessage message) {
    switch (message.type) {
      case DeliveryNotificationType.newDelivery:
      case DeliveryNotificationType.urgentDelivery:
        return AndroidNotificationDetails(
          _getChannelIdForType(message.type),
          _getChannelNameForType(message.type),
          styleInformation: BigTextStyleInformation(
            message.body,
            htmlFormatBigText: true,
            contentTitle: message.title,
            htmlFormatContentTitle: true,
            summaryText: 'Delivery Assignment',
            htmlFormatSummaryText: true,
          ),
        );
      case DeliveryNotificationType.routeUpdate:
        return AndroidNotificationDetails(
          _getChannelIdForType(message.type),
          _getChannelNameForType(message.type),
          styleInformation: InboxStyleInformation(
            [message.body],
            htmlFormatLines: true,
            contentTitle: message.title,
            htmlFormatContentTitle: true,
            summaryText: 'Route Information',
            htmlFormatSummaryText: true,
          ),
        );
      default:
        return AndroidNotificationDetails(
          _getChannelIdForType(message.type),
          _getChannelNameForType(message.type),
          styleInformation: BigTextStyleInformation(message.body),
        );
    }
  }

  // Get notification actions based on type
  List<AndroidNotificationAction>? _getNotificationActions(DeliveryNotificationType type) {
    switch (type) {
      case DeliveryNotificationType.newDelivery:
        return [
          const AndroidNotificationAction(
            'accept_delivery',
            'Accept',
            icon: DrawableResourceAndroidBitmap('ic_check'),
          ),
          const AndroidNotificationAction(
            'view_details',
            'View Details',
            icon: DrawableResourceAndroidBitmap('ic_info'),
          ),
        ];
      case DeliveryNotificationType.customerMessage:
        return [
          const AndroidNotificationAction(
            'quick_reply',
            'Quick Reply',
            icon: DrawableResourceAndroidBitmap('ic_reply'),
            inputs: [AndroidNotificationActionInput(label: 'Reply...')],
          ),
          const AndroidNotificationAction(
            'call_customer',
            'Call',
            icon: DrawableResourceAndroidBitmap('ic_call'),
          ),
        ];
      case DeliveryNotificationType.activeDelivery:
        return [
          const AndroidNotificationAction(
            'mark_delivered',
            'Mark Delivered',
            icon: DrawableResourceAndroidBitmap('ic_check_circle'),
          ),
          const AndroidNotificationAction(
            'contact_customer',
            'Contact',
            icon: DrawableResourceAndroidBitmap('ic_message'),
          ),
        ];
      default:
        return null;
    }
  }

  // Notification type helpers for delivery app
  String _getChannelIdForType(DeliveryNotificationType type) {
    switch (type) {
      case DeliveryNotificationType.newDelivery:
        return 'new_deliveries';
      case DeliveryNotificationType.routeUpdate:
        return 'route_updates';
      case DeliveryNotificationType.urgentDelivery:
        return 'urgent_deliveries';
      case DeliveryNotificationType.trafficAlert:
        return 'traffic_alerts';
      case DeliveryNotificationType.customerMessage:
        return 'customer_messages';
      case DeliveryNotificationType.payment:
        return 'payments';
      case DeliveryNotificationType.system:
        return 'system';
      case DeliveryNotificationType.activeDelivery:
        return 'new_deliveries';
    }
  }

  String _getChannelNameForType(DeliveryNotificationType type) {
    switch (type) {
      case DeliveryNotificationType.newDelivery:
        return 'New Deliveries';
      case DeliveryNotificationType.routeUpdate:
        return 'Route Updates';
      case DeliveryNotificationType.urgentDelivery:
        return 'Urgent Deliveries';
      case DeliveryNotificationType.trafficAlert:
        return 'Traffic Alerts';
      case DeliveryNotificationType.customerMessage:
        return 'Customer Messages';
      case DeliveryNotificationType.payment:
        return 'Payment Notifications';
      case DeliveryNotificationType.system:
        return 'System Notifications';
      case DeliveryNotificationType.activeDelivery:
        return 'Active Deliveries';
    }
  }

  String _getChannelDescriptionForType(DeliveryNotificationType type) {
    switch (type) {
      case DeliveryNotificationType.newDelivery:
        return 'Notifications for new delivery assignments';
      case DeliveryNotificationType.routeUpdate:
        return 'Notifications for route changes and optimizations';
      case DeliveryNotificationType.urgentDelivery:
        return 'Notifications for time-sensitive deliveries';
      case DeliveryNotificationType.trafficAlert:
        return 'Notifications for traffic conditions and route alerts';
      case DeliveryNotificationType.customerMessage:
        return 'Notifications for customer communication';
      case DeliveryNotificationType.payment:
        return 'Notifications for payment updates and earnings';
      case DeliveryNotificationType.system:
        return 'Important system and policy notifications';
      case DeliveryNotificationType.activeDelivery:
        return 'Notifications for ongoing deliveries';
    }
  }

  Importance _getImportanceForType(DeliveryNotificationType type) {
    switch (type) {
      case DeliveryNotificationType.newDelivery:
      case DeliveryNotificationType.urgentDelivery:
      case DeliveryNotificationType.customerMessage:
      case DeliveryNotificationType.payment:
      case DeliveryNotificationType.system:
        return Importance.max;
      case DeliveryNotificationType.routeUpdate:
      case DeliveryNotificationType.activeDelivery:
        return Importance.high;
      case DeliveryNotificationType.trafficAlert:
        return Importance.defaultImportance;
    }
  }

  // Check if notification should be shown
  bool _shouldShowNotification(NotificationMessage message) {
    if (!_notificationsEnabled) return false;

    switch (message.type) {
      case DeliveryNotificationType.newDelivery:
      case DeliveryNotificationType.activeDelivery:
        return _newDeliveryNotifications;
      case DeliveryNotificationType.routeUpdate:
        return _routeUpdateNotifications;
      case DeliveryNotificationType.urgentDelivery:
        return _urgentDeliveryNotifications;
      case DeliveryNotificationType.trafficAlert:
        return _trafficAlertNotifications;
      case DeliveryNotificationType.customerMessage:
        return _customerMessageNotifications;
      case DeliveryNotificationType.payment:
        return _paymentNotifications;
      case DeliveryNotificationType.system:
        return _systemNotifications;
    }
  }

  // Topic subscriptions for delivery personnel
  Future<void> subscribeToDeliveryTopics() async {
    await _firebaseMessaging.subscribeToTopic('delivery_personnel');
    await _firebaseMessaging.subscribeToTopic('traffic_alerts');
    await _firebaseMessaging.subscribeToTopic('system_announcements');
    
    if (kDebugMode) {
      debugPrint('Subscribed to delivery topics');
    }
  }

  Future<void> subscribeToDeliveryPersonSpecificTopic(String deliveryPersonId) async {
    await _firebaseMessaging.subscribeToTopic('delivery_person_$deliveryPersonId');
    
    if (kDebugMode) {
      debugPrint('Subscribed to delivery_person_$deliveryPersonId topic');
    }
  }

  Future<void> subscribeToZoneNotifications(String zoneId) async {
    await _firebaseMessaging.subscribeToTopic('delivery_zone_$zoneId');
    
    if (kDebugMode) {
      debugPrint('Subscribed to delivery_zone_$zoneId topic');
    }
  }

  Future<void> unsubscribeFromZoneNotifications(String zoneId) async {
    await _firebaseMessaging.unsubscribeFromTopic('delivery_zone_$zoneId');
    
    if (kDebugMode) {
      debugPrint('Unsubscribed from delivery_zone_$zoneId topic');
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
    bool? newDeliveryNotifications,
    bool? routeUpdateNotifications,
    bool? urgentDeliveryNotifications,
    bool? trafficAlertNotifications,
    bool? customerMessageNotifications,
    bool? paymentNotifications,
    bool? systemNotifications,
  }) async {
    if (notificationsEnabled != null) _notificationsEnabled = notificationsEnabled;
    if (soundEnabled != null) _soundEnabled = soundEnabled;
    if (vibrationEnabled != null) _vibrationEnabled = vibrationEnabled;
    if (newDeliveryNotifications != null) _newDeliveryNotifications = newDeliveryNotifications;
    if (routeUpdateNotifications != null) _routeUpdateNotifications = routeUpdateNotifications;
    if (urgentDeliveryNotifications != null) _urgentDeliveryNotifications = urgentDeliveryNotifications;
    if (trafficAlertNotifications != null) _trafficAlertNotifications = trafficAlertNotifications;
    if (customerMessageNotifications != null) _customerMessageNotifications = customerMessageNotifications;
    if (paymentNotifications != null) _paymentNotifications = paymentNotifications;
    if (systemNotifications != null) _systemNotifications = systemNotifications;

    await _saveSettings();
    await _updateServerSettings();

    if (kDebugMode) {
      debugPrint('Delivery notification settings updated');
    }
  }

  // Server communication
  Future<void> _updateTokenOnServer(String token) async {
    if (_baseUrl == null) return;

    try {
      await _dio.post('$_baseUrl/api/notifications/token', data: {
        'fcm_token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'app_type': 'delivery',
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
        'new_delivery_notifications': _newDeliveryNotifications,
        'route_update_notifications': _routeUpdateNotifications,
        'urgent_delivery_notifications': _urgentDeliveryNotifications,
        'traffic_alert_notifications': _trafficAlertNotifications,
        'customer_message_notifications': _customerMessageNotifications,
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
    await prefs.setBool('new_delivery_notifications', _newDeliveryNotifications);
    await prefs.setBool('route_update_notifications', _routeUpdateNotifications);
    await prefs.setBool('urgent_delivery_notifications', _urgentDeliveryNotifications);
    await prefs.setBool('traffic_alert_notifications', _trafficAlertNotifications);
    await prefs.setBool('customer_message_notifications', _customerMessageNotifications);
    await prefs.setBool('payment_notifications', _paymentNotifications);
    await prefs.setBool('system_notifications', _systemNotifications);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _newDeliveryNotifications = prefs.getBool('new_delivery_notifications') ?? true;
    _routeUpdateNotifications = prefs.getBool('route_update_notifications') ?? true;
    _urgentDeliveryNotifications = prefs.getBool('urgent_delivery_notifications') ?? true;
    _trafficAlertNotifications = prefs.getBool('traffic_alert_notifications') ?? true;
    _customerMessageNotifications = prefs.getBool('customer_message_notifications') ?? true;
    _paymentNotifications = prefs.getBool('payment_notifications') ?? true;
    _systemNotifications = prefs.getBool('system_notifications') ?? true;
  }

  Future<void> _saveNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _notificationHistory.map((n) => n.toJson()).toList();
    await prefs.setString('notification_history_delivery', jsonEncode(historyJson));
    await prefs.setInt('unread_count_delivery', _unreadCount);
  }

  Future<void> _loadNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('notification_history_delivery');
    _unreadCount = prefs.getInt('unread_count_delivery') ?? 0;
    
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
      title: 'Test Delivery Notification',
      body: 'This is a test notification for the delivery app',
      type: DeliveryNotificationType.system,
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

// Delivery-specific notification types
enum DeliveryNotificationType {
  newDelivery,
  activeDelivery,
  routeUpdate,
  urgentDelivery,
  trafficAlert,
  customerMessage,
  payment,
  system,
}

class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final DeliveryNotificationType type;
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

  static DeliveryNotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'new_delivery':
        return DeliveryNotificationType.newDelivery;
      case 'active_delivery':
        return DeliveryNotificationType.activeDelivery;
      case 'route_update':
        return DeliveryNotificationType.routeUpdate;
      case 'urgent_delivery':
        return DeliveryNotificationType.urgentDelivery;
      case 'traffic_alert':
        return DeliveryNotificationType.trafficAlert;
      case 'customer_message':
        return DeliveryNotificationType.customerMessage;
      case 'payment':
        return DeliveryNotificationType.payment;
      default:
        return DeliveryNotificationType.system;
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
      type: DeliveryNotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeliveryNotificationType.system,
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
    DeliveryNotificationType? type,
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