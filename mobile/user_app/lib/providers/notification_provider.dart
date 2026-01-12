import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider(this._notificationService);

  // State variables
  bool _isInitialized = false;
  bool _isLoading = false;
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  NotificationSettings _settings = NotificationSettings.defaultSettings();
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  NotificationSettings get settings => _settings;
  String? get error => _error;

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize notification service with callbacks
      await _notificationService.initialize(
        apiService: _notificationService._apiService,
        onNotificationTap: _handleNotificationTap,
        onNotificationReceived: _handleNotificationReceived,
      );

      // Load initial data
      await loadNotifications();
      await loadSettings();

      // Subscribe to relevant topics based on user role
      await _subscribeToTopics();

      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize notifications: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (!refresh && _notifications.isNotEmpty) return;

    _isLoading = true;
    if (refresh) notifyListeners();

    try {
      _notifications = await _notificationService.getNotificationHistory();
      _updateUnreadCount();
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load notification settings
  Future<void> loadSettings() async {
    try {
      _settings = await _notificationService.getNotificationSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load notification settings: $e');
    }
  }

  // Update notification settings
  Future<bool> updateSettings(NotificationSettings newSettings) async {
    try {
      final success = await _notificationService.updateNotificationSettings(newSettings);
      
      if (success) {
        _settings = newSettings;
        
        // Update topic subscriptions based on settings
        await _updateTopicSubscriptions();
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update notification settings: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = NotificationItem(
            id: _notifications[index].id,
            title: _notifications[index].title,
            body: _notifications[index].body,
            type: _notifications[index].type,
            data: _notifications[index].data,
            isRead: true,
            createdAt: _notifications[index].createdAt,
          );
          
          _updateUnreadCount();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      
      for (final notification in unreadNotifications) {
        await markAsRead(notification.id);
      }
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  // Send order notification
  Future<bool> sendOrderNotification({
    required String userId,
    required String title,
    required String body,
    required String orderId,
    required String orderStatus,
    Map<String, dynamic>? additionalData,
  }) async {
    return await _notificationService.sendOrderNotification(
      userId: userId,
      title: title,
      body: body,
      orderId: orderId,
      type: 'order_update',
      additionalData: {
        'order_status': orderStatus,
        ...?additionalData,
      },
    );
  }

  // Send delivery notification
  Future<bool> sendDeliveryNotification({
    required String userId,
    required String title,
    required String body,
    required String orderId,
    required String deliveryStatus,
    String? estimatedTime,
  }) async {
    return await _notificationService.sendOrderNotification(
      userId: userId,
      title: title,
      body: body,
      orderId: orderId,
      type: 'delivery_update',
      additionalData: {
        'delivery_status': deliveryStatus,
        'estimated_time': estimatedTime,
      },
    );
  }

  // Send promotional notification
  Future<bool> sendPromotionalNotification({
    required String title,
    required String body,
    required String imageUrl,
    required String actionUrl,
    List<String>? targetUserIds,
  }) async {
    return await _notificationService.sendPromotionalNotification(
      title: title,
      body: body,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      targetUserIds: targetUserIds,
    );
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderId = data['order_id'] as String?;

    switch (type) {
      case 'order_update':
        _navigateToOrderDetails(orderId);
        break;
      case 'delivery_update':
        _navigateToOrderTracking(orderId);
        break;
      case 'promotional':
        final actionUrl = data['action_url'] as String?;
        _navigateToPromotion(actionUrl);
        break;
      case 'new_message':
        _navigateToMessages();
        break;
      default:
        _navigateToNotifications();
        break;
    }
  }

  // Handle notification received
  void _handleNotificationReceived(Map<String, dynamic> data) {
    // Add notification to local list
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? 'New Notification',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _updateUnreadCount();
    notifyListeners();
  }

  // Subscribe to topics based on user role
  Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to general topics
      await _notificationService.subscribeToTopic('general');
      
      if (_settings.promotionalOffers) {
        await _notificationService.subscribeToTopic('promotions');
      }
      
      if (_settings.appUpdates) {
        await _notificationService.subscribeToTopic('app_updates');
      }

      // Subscribe to role-specific topics
      // This would be determined based on user role
      // await _notificationService.subscribeToTopic('customers');
      
    } catch (e) {
      debugPrint('Failed to subscribe to topics: $e');
    }
  }

  // Update topic subscriptions based on settings
  Future<void> _updateTopicSubscriptions() async {
    try {
      if (_settings.promotionalOffers) {
        await _notificationService.subscribeToTopic('promotions');
      } else {
        await _notificationService.unsubscribeFromTopic('promotions');
      }

      if (_settings.appUpdates) {
        await _notificationService.subscribeToTopic('app_updates');
      } else {
        await _notificationService.unsubscribeFromTopic('app_updates');
      }
    } catch (e) {
      debugPrint('Failed to update topic subscriptions: $e');
    }
  }

  // Update unread count
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // Navigation methods (to be implemented based on app navigation)
  void _navigateToOrderDetails(String? orderId) {
    // TODO: Navigate to order details screen
    debugPrint('Navigate to order details: $orderId');
  }

  void _navigateToOrderTracking(String? orderId) {
    // TODO: Navigate to order tracking screen
    debugPrint('Navigate to order tracking: $orderId');
  }

  void _navigateToPromotion(String? actionUrl) {
    // TODO: Navigate to promotion or external URL
    debugPrint('Navigate to promotion: $actionUrl');
  }

  void _navigateToMessages() {
    // TODO: Navigate to messages screen
    debugPrint('Navigate to messages');
  }

  void _navigateToNotifications() {
    // TODO: Navigate to notifications screen
    debugPrint('Navigate to notifications');
  }

  // Clear notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear notifications: $e');
    }
  }

  // Get notifications by type
  List<NotificationItem> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh notifications
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }

  // Dispose
  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}