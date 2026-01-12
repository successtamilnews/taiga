import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/cart.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  static const String apiBaseUrl = '$baseUrl/api';
  
  late Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await logout();
        }
        handler.next(error);
      },
    ));

    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // Authentication
  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        await _saveToken(data['token']);
        final user = User.fromJson(data['user']);
        return ApiResponse.success(user);
      } else {
        return ApiResponse.error('Login failed');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    UserType userType = UserType.customer,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone,
        'user_type': userType.toString().split('.').last,
      });

      if (response.statusCode == 201) {
        final data = response.data;
        await _saveToken(data['token']);
        final user = User.fromJson(data['user']);
        return ApiResponse.success(user);
      } else {
        return ApiResponse.error('Registration failed');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      await _dio.post('/auth/logout');
      await _clearToken();
      return ApiResponse.success(null);
    } catch (e) {
      await _clearToken();
      return ApiResponse.success(null);
    }
  }

  Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await _dio.get('/auth/user');
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        return ApiResponse.success(user);
      } else {
        return ApiResponse.error('Failed to get profile');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/auth/user', data: data);
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        return ApiResponse.success(user);
      } else {
        return ApiResponse.error('Failed to update profile');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Products
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? categoryIds,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null) queryParams['search'] = search;
      if (categoryIds != null) queryParams['category_ids'] = categoryIds;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;

      final response = await _dio.get('/products', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final List<Product> products = (response.data['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
        return ApiResponse.success(products);
      } else {
        return ApiResponse.error('Failed to load products');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Product>> getProduct(int productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      if (response.statusCode == 200) {
        final product = Product.fromJson(response.data);
        return ApiResponse.success(product);
      } else {
        return ApiResponse.error('Failed to load product');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<List<ProductCategory>>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.statusCode == 200) {
        final List<ProductCategory> categories = (response.data as List)
            .map((json) => ProductCategory.fromJson(json))
            .toList();
        return ApiResponse.success(categories);
      } else {
        return ApiResponse.error('Failed to load categories');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Orders
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 1,
    int perPage = 20,
    OrderStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null) {
        queryParams['status'] = status.toString().split('.').last;
      }

      final response = await _dio.get('/orders', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final List<Order> orders = (response.data['data'] as List)
            .map((json) => Order.fromJson(json))
            .toList();
        return ApiResponse.success(orders);
      } else {
        return ApiResponse.error('Failed to load orders');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Order>> getOrder(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      if (response.statusCode == 200) {
        final order = Order.fromJson(response.data);
        return ApiResponse.success(order);
      } else {
        return ApiResponse.error('Failed to load order');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Order>> createOrder({
    required List<CartItem> items,
    required Address shippingAddress,
    Address? billingAddress,
    String? paymentMethodId,
    String? couponCode,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/orders', data: {
        'items': items.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.finalPrice,
          'selected_attributes': item.selectedAttributes,
        }).toList(),
        'shipping_address': shippingAddress.toJson(),
        'billing_address': billingAddress?.toJson(),
        'payment_method_id': paymentMethodId,
        'coupon_code': couponCode,
        'notes': notes,
      });

      if (response.statusCode == 201) {
        final order = Order.fromJson(response.data);
        return ApiResponse.success(order);
      } else {
        return ApiResponse.error('Failed to create order');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Cart (server-side)
  Future<ApiResponse<Cart>> getCart() async {
    try {
      final response = await _dio.get('/cart');
      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data);
        return ApiResponse.success(cart);
      } else {
        return ApiResponse.error('Failed to load cart');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Cart>> addToCart(int productId, int quantity, {Map<String, dynamic>? attributes}) async {
    try {
      final response = await _dio.post('/cart/add', data: {
        'product_id': productId,
        'quantity': quantity,
        'attributes': attributes,
      });

      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data);
        return ApiResponse.success(cart);
      } else {
        return ApiResponse.error('Failed to add to cart');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Cart>> updateCartItem(int productId, int quantity) async {
    try {
      final response = await _dio.put('/cart/update', data: {
        'product_id': productId,
        'quantity': quantity,
      });

      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data);
        return ApiResponse.success(cart);
      } else {
        return ApiResponse.error('Failed to update cart');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Cart>> removeFromCart(int productId) async {
    try {
      final response = await _dio.delete('/cart/remove/$productId');
      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data);
        return ApiResponse.success(cart);
      } else {
        return ApiResponse.error('Failed to remove from cart');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Cart>> clearCart() async {
    try {
      final response = await _dio.delete('/cart/clear');
      if (response.statusCode == 200) {
        final cart = Cart.fromJson(response.data);
        return ApiResponse.success(cart);
      } else {
        return ApiResponse.error('Failed to clear cart');
      }
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Utility methods
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'Unknown error';
          return '$message (Status: $statusCode)';
        case DioExceptionType.cancel:
          return 'Request cancelled';
        case DioExceptionType.unknown:
        default:
          return 'Network error. Please check your connection.';
      }
    }
    return 'An unexpected error occurred';
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse.success(this.data) : success = true, error = null;
  ApiResponse.error(this.error) : success = false, data = null;
}