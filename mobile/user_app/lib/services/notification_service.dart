import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  late ApiService _apiService;
  Function(Map<String, dynamic>)? _onNotificationTap;
  Function(Map<String, dynamic>)? _onNotificationReceived;

  // Initialize notification service
  Future<void> initialize({
    required ApiService apiService,
    Function(Map<String, dynamic>)? onNotificationTap,
    Function(Map<String, dynamic>)? onNotificationReceived,
  }) async {
    _apiService = apiService;
    _onNotificationTap = onNotificationTap;
    _onNotificationReceived = onNotificationReceived;

    await _initializeFirebaseMessaging();
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _configureHandlers();
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      
      if (token != null) {
        await _sendTokenToServer(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) async {
        debugPrint('FCM Token refreshed: $token');
        await _sendTokenToServer(token);
      });

    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidInitialize = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInitialize = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      // Request Firebase messaging permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notification permissions denied');
        return false;
      }

      // Request system notification permissions
      final permissionStatus = await Permission.notification.request();
      
      return permissionStatus.isGranted && 
             settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // Configure message handlers
  Future<void> _configureHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message.data);
    });

    // Handle app launch from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage.data);
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'Taiga',
        body: notification.body ?? '',
        payload: data,
      );
    }

    _onNotificationReceived?.call(data);
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'taiga_notifications',
      'Taiga Notifications',
      channelDescription: 'General notifications for Taiga app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload != null ? _encodePayload(payload) : null,
    );
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    _onNotificationTap?.call(data);
  }

  // Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _handleNotificationTap(data);
    }
  }

  // Send FCM token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      await _apiService.post('/notifications/fcm-token', {
        'token': token,
        'platform': defaultTargetPlatform.name,
      });
      debugPrint('FCM token sent to server successfully');
    } catch (e) {
      debugPrint('Error sending FCM token to server: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Send order notification
  Future<bool> sendOrderNotification({
    required String userId,
    required String title,
    required String body,
    required String orderId,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _apiService.post('/notifications/send', {
        'user_id': userId,
        'title': title,
        'body': body,
        'data': {
          'type': type,
          'order_id': orderId,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          ...?additionalData,
        },
      });

      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error sending order notification: $e');
      return false;
    }
  }

  // Send bulk notification
  Future<bool> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _apiService.post('/notifications/send-bulk', {
        'user_ids': userIds,
        'title': title,
        'body': body,
        'data': {
          'type': type,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          ...?data,
        },
      });

      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error sending bulk notification: $e');
      return false;
    }
  }

  // Send promotional notification
  Future<bool> sendPromotionalNotification({
    required String title,
    required String body,
    required String imageUrl,
    required String actionUrl,
    List<String>? targetUserIds,
    String? topic,
  }) async {
    try {
      final response = await _apiService.post('/notifications/promotional', {
        'title': title,
        'body': body,
        'image_url': imageUrl,
        'action_url': actionUrl,
        'target_user_ids': targetUserIds,
        'topic': topic,
        'data': {
          'type': 'promotional',
          'action_url': actionUrl,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      });

      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error sending promotional notification: $e');
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.put('/notifications/$notificationId/read', {});
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // Get notification history
  Future<List<NotificationItem>> getNotificationHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get('/notifications/history', queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      if (response['success']) {
        return (response['data'] as List)
            .map((json) => NotificationItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notification history: $e');
      return [];
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final response = await _apiService.get('/notifications/settings');
      return NotificationSettings.fromJson(response['data'] ?? {});
    } catch (e) {
      debugPrint('Error fetching notification settings: $e');
      return NotificationSettings.defaultSettings();
    }
  }

  // Update notification settings
  Future<bool> updateNotificationSettings(NotificationSettings settings) async {
    try {
      final response = await _apiService.put('/notifications/settings', settings.toJson());
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      return false;
    }
  }

  // Helper methods
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final data = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        data[parts[0]] = parts[1];
      }
    }
    return data;
  }

  // Dispose
  void dispose() {
    // Clean up resources if needed
  }
}

// Notification item model
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Notification settings model
class NotificationSettings {
  final bool orderUpdates;
  final bool promotionalOffers;
  final bool deliveryUpdates;
  final bool newMessages;
  final bool appUpdates;
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationSettings({
    required this.orderUpdates,
    required this.promotionalOffers,
    required this.deliveryUpdates,
    required this.newMessages,
    required this.appUpdates,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      orderUpdates: json['order_updates'] ?? true,
      promotionalOffers: json['promotional_offers'] ?? true,
      deliveryUpdates: json['delivery_updates'] ?? true,
      newMessages: json['new_messages'] ?? true,
      appUpdates: json['app_updates'] ?? true,
      soundEnabled: json['sound_enabled'] ?? true,
      vibrationEnabled: json['vibration_enabled'] ?? true,
    );
  }

  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      orderUpdates: true,
      promotionalOffers: true,
      deliveryUpdates: true,
      newMessages: true,
      appUpdates: true,
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_updates': orderUpdates,
      'promotional_offers': promotionalOffers,
      'delivery_updates': deliveryUpdates,
      'new_messages': newMessages,
      'app_updates': appUpdates,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
    };
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  
  // Handle background notification logic here
  // This runs even when the app is completely closed
}