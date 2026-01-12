import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<ProductCategory> _categories = [];
  
  bool _isLoading = false;
  bool _hasMoreProducts = true;
  String? _error;
  int _currentPage = 1;
  String? _currentSearchQuery;
  List<int>? _currentCategoryIds;
  double? _currentMinPrice;
  double? _currentMaxPrice;
  String _currentSortBy = 'created_at';
  String _currentSortOrder = 'desc';

  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<ProductCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMoreProducts => _hasMoreProducts;
  String? get error => _error;

  ProductProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadCategories(),
      loadFeaturedProducts(),
      loadProducts(refresh: true),
    ]);
  }

  Future<void> loadCategories() async {
    try {
      final response = await _apiService.getCategories();
      if (response.success && response.data != null) {
        _categories = response.data!;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load categories');
    }
  }

  Future<void> loadFeaturedProducts() async {
    try {
      final response = await _apiService.getProducts(
        perPage: 10,
        sortBy: 'featured',
      );
      if (response.success && response.data != null) {
        _featuredProducts = response.data!.where((p) => p.featured).toList();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load featured products');
    }
  }

  Future<void> loadProducts({
    bool refresh = false,
    String? search,
    List<int>? categoryIds,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    if (refresh) {
      _products.clear();
      _currentPage = 1;
      _hasMoreProducts = true;
    }

    if (!_hasMoreProducts || _isLoading) return;

    _setLoading(true);
    _clearError();

    // Update current filters
    _currentSearchQuery = search;
    _currentCategoryIds = categoryIds;
    _currentMinPrice = minPrice;
    _currentMaxPrice = maxPrice;
    _currentSortBy = sortBy;
    _currentSortOrder = sortOrder;

    try {
      final response = await _apiService.getProducts(
        page: _currentPage,
        search: search,
        categoryIds: categoryIds,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      if (response.success && response.data != null) {
        final newProducts = response.data!;
        
        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }

        _currentPage++;
        _hasMoreProducts = newProducts.isNotEmpty;
        notifyListeners();
      } else {
        _setError(response.error ?? 'Failed to load products');
      }
    } catch (e) {
      _setError('Failed to load products');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts(
      refresh: true,
      search: _currentSearchQuery,
      categoryIds: _currentCategoryIds,
      minPrice: _currentMinPrice,
      maxPrice: _currentMaxPrice,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    );
  }

  Future<void> loadMoreProducts() async {
    await loadProducts(
      search: _currentSearchQuery,
      categoryIds: _currentCategoryIds,
      minPrice: _currentMinPrice,
      maxPrice: _currentMaxPrice,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    );
  }

  Future<Product?> getProduct(int productId) async {
    try {
      final response = await _apiService.getProduct(productId);
      if (response.success && response.data != null) {
        return response.data!;
      }
      return null;
    } catch (e) {
      _setError('Failed to load product');
      return null;
    }
  }

  void searchProducts(String query) {
    loadProducts(
      refresh: true,
      search: query.trim().isEmpty ? null : query.trim(),
    );
  }

  void filterProducts({
    List<int>? categoryIds,
    double? minPrice,
    double? maxPrice,
  }) {
    loadProducts(
      refresh: true,
      search: _currentSearchQuery,
      categoryIds: categoryIds,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  void sortProducts(String sortBy, {String sortOrder = 'desc'}) {
    loadProducts(
      refresh: true,
      search: _currentSearchQuery,
      categoryIds: _currentCategoryIds,
      minPrice: _currentMinPrice,
      maxPrice: _currentMaxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  void clearFilters() {
    loadProducts(refresh: true);
  }

  Product? findProductById(int productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsByCategory(int categoryId) {
    return _products
        .where((product) => 
            product.categories.any((cat) => cat.id == categoryId))
        .toList();
  }

  List<Product> getProductsByVendor(int vendorId) {
    return _products
        .where((product) => product.vendor.id == vendorId)
        .toList();
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