import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Cart _cart = Cart();
  bool _isLoading = false;
  String? _error;

  Cart get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart.itemCount;
  double get total => _cart.total;
  double get subtotal => _cart.subtotal;
  bool get isEmpty => _cart.isEmpty;

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCart();
      if (response.success && response.data != null) {
        _cart = response.data!;
        notifyListeners();
      } else {
        _setError(response.error ?? 'Failed to load cart');
      }
    } catch (e) {
      _setError('Failed to load cart');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addToCart(
    Product product, {
    int quantity = 1,
    Map<String, dynamic>? attributes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.addToCart(
        product.id,
        quantity,
        attributes: attributes,
      );

      if (response.success && response.data != null) {
        _cart = response.data!;
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to add to cart');
        return false;
      }
    } catch (e) {
      _setError('Failed to add to cart');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateQuantity(Product product, int quantity) async {
    if (quantity <= 0) {
      return await removeFromCart(product);
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateCartItem(product.id, quantity);

      if (response.success && response.data != null) {
        _cart = response.data!;
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to update cart');
        return false;
      }
    } catch (e) {
      _setError('Failed to update cart');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeFromCart(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.removeFromCart(product.id);

      if (response.success && response.data != null) {
        _cart = response.data!;
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to remove from cart');
        return false;
      }
    } catch (e) {
      _setError('Failed to remove from cart');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> clearCart() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.clearCart();

      if (response.success && response.data != null) {
        _cart = response.data!;
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to clear cart');
        return false;
      }
    } catch (e) {
      _setError('Failed to clear cart');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  CartItem? getCartItem(Product product) {
    try {
      return _cart.items.firstWhere(
        (item) => item.product.id == product.id,
      );
    } catch (e) {
      return null;
    }
  }

  int getProductQuantity(Product product) {
    final item = getCartItem(product);
    return item?.quantity ?? 0;
  }

  bool isInCart(Product product) {
    return getCartItem(product) != null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
  }
}