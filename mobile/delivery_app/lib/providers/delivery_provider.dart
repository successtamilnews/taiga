import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class DeliveryProvider with ChangeNotifier {
  final ApiService _apiService;

  DeliveryProvider(this._apiService);

  // Loading states
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  
  // Orders
  List<Order> _activeOrders = [];
  List<Order> _recentOrders = [];
  List<Order> _allOrders = [];
  
  // Delivery stats
  int _todayDeliveries = 0;
  double _todayEarnings = 0.0;
  double _weeklyEarnings = 0.0;
  double _monthlyEarnings = 0.0;
  
  // Current delivery
  Order? _currentOrder;
  bool _isOnline = false;
  String _currentLocation = '';

  // Getters
  bool get isLoading => _isLoading;
  bool get isUpdatingStatus => _isUpdatingStatus;
  List<Order> get activeOrders => _activeOrders;
  List<Order> get recentOrders => _recentOrders;
  List<Order> get allOrders => _allOrders;
  int get todayDeliveries => _todayDeliveries;
  double get todayEarnings => _todayEarnings;
  double get weeklyEarnings => _weeklyEarnings;
  double get monthlyEarnings => _monthlyEarnings;
  Order? get currentOrder => _currentOrder;
  bool get isOnline => _isOnline;
  String get currentLocation => _currentLocation;

  // Load assigned orders
  Future<void> loadAssignedOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/delivery/orders');
      
      if (response['success']) {
        _allOrders = (response['data'] as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();

        // Filter active orders
        _activeOrders = _allOrders
            .where((order) => ['assigned', 'picked_up', 'in_transit'].contains(order.status))
            .toList();

        // Filter recent delivered orders
        _recentOrders = _allOrders
            .where((order) => order.status == 'delivered')
            .take(10)
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load delivery stats
  Future<void> loadDeliveryStats() async {
    try {
      final response = await _apiService.get('/delivery/stats');
      
      if (response['success']) {
        final stats = response['data'];
        _todayDeliveries = stats['today_deliveries'] ?? 0;
        _todayEarnings = (stats['today_earnings'] ?? 0.0).toDouble();
        _weeklyEarnings = (stats['weekly_earnings'] ?? 0.0).toDouble();
        _monthlyEarnings = (stats['monthly_earnings'] ?? 0.0).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading delivery stats: $e');
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status, {String? notes}) async {
    _isUpdatingStatus = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/delivery/orders/$orderId/status', {
        'status': status,
        'delivery_notes': notes,
        'delivered_at': status == 'delivered' ? DateTime.now().toIso8601String() : null,
      });

      if (response['success']) {
        // Update local order
        final orderIndex = _allOrders.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          _allOrders[orderIndex] = Order.fromJson(response['data']);
          
          // Refresh filtered lists
          _activeOrders = _allOrders
              .where((order) => ['assigned', 'picked_up', 'in_transit'].contains(order.status))
              .toList();
              
          _recentOrders = _allOrders
              .where((order) => order.status == 'delivered')
              .take(10)
              .toList();
        }

        // If delivered, refresh stats
        if (status == 'delivered') {
          await loadDeliveryStats();
        }

        _isUpdatingStatus = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }

    _isUpdatingStatus = false;
    notifyListeners();
    return false;
  }

  // Accept order
  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _apiService.post('/delivery/orders/$orderId/accept', {});
      
      if (response['success']) {
        await loadAssignedOrders();
        return true;
      }
    } catch (e) {
      debugPrint('Error accepting order: $e');
    }
    return false;
  }

  // Pick up order
  Future<bool> pickUpOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'picked_up');
  }

  // Start delivery
  Future<bool> startDelivery(String orderId) async {
    return await updateOrderStatus(orderId, 'in_transit');
  }

  // Complete delivery
  Future<bool> completeDelivery(String orderId, {String? notes}) async {
    return await updateOrderStatus(orderId, 'delivered', notes: notes);
  }

  // Update online status
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await _apiService.put('/delivery/status', {
        'is_online': isOnline,
        'location': _currentLocation,
      });

      if (response['success']) {
        _isOnline = isOnline;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
    return false;
  }

  // Update location
  Future<void> updateLocation(String location) async {
    _currentLocation = location;
    
    try {
      await _apiService.put('/delivery/location', {
        'location': location,
        'latitude': 0.0, // Add actual coordinates
        'longitude': 0.0,
      });
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  // Get order details
  Future<Order?> getOrderDetails(String orderId) async {
    try {
      final response = await _apiService.get('/delivery/orders/$orderId');
      
      if (response['success']) {
        return Order.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
    }
    return null;
  }

  // Get delivery history
  Future<List<Order>> getDeliveryHistory({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _apiService.get('/delivery/orders/history', queryParams: queryParams);
      
      if (response['success']) {
        return (response['data'] as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading delivery history: $e');
    }
    return [];
  }

  // Get earnings report
  Future<Map<String, dynamic>> getEarningsReport({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _apiService.get('/delivery/earnings', queryParams: queryParams);
      
      if (response['success']) {
        return response['data'];
      }
    } catch (e) {
      debugPrint('Error loading earnings report: $e');
    }
    return {};
  }

  // Submit delivery proof
  Future<bool> submitDeliveryProof({
    required String orderId,
    String? photoPath,
    String? signature,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{
        'order_id': orderId,
      };
      
      if (photoPath != null) data['delivery_photo'] = photoPath;
      if (signature != null) data['signature'] = signature;
      if (notes != null) data['notes'] = notes;

      final response = await _apiService.post('/delivery/orders/$orderId/proof', data);
      
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error submitting delivery proof: $e');
      return false;
    }
  }

  // Report delivery issue
  Future<bool> reportDeliveryIssue({
    required String orderId,
    required String issueType,
    required String description,
    String? photoPath,
  }) async {
    try {
      final data = {
        'order_id': orderId,
        'issue_type': issueType,
        'description': description,
      };
      
      if (photoPath != null) data['photo'] = photoPath;

      final response = await _apiService.post('/delivery/orders/$orderId/issue', data);
      
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('Error reporting delivery issue: $e');
      return false;
    }
  }

  // Clear data
  void clear() {
    _activeOrders.clear();
    _recentOrders.clear();
    _allOrders.clear();
    _todayDeliveries = 0;
    _todayEarnings = 0.0;
    _weeklyEarnings = 0.0;
    _monthlyEarnings = 0.0;
    _currentOrder = null;
    _isOnline = false;
    _currentLocation = '';
    notifyListeners();
  }

  // Reset states
  void reset() {
    _isLoading = false;
    _isUpdatingStatus = false;
    notifyListeners();
  }
}