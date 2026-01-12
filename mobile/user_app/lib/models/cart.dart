class CartItem {
  final Product product;
  final int quantity;
  final Map<String, dynamic>? selectedAttributes;

  CartItem({
    required this.product,
    required this.quantity,
    this.selectedAttributes,
  });

  double get total => product.finalPrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    Map<String, dynamic>? selectedAttributes,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      selectedAttributes: json['selected_attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'selected_attributes': selectedAttributes,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.product.id == product.id &&
        _mapsEqual(other.selectedAttributes, selectedAttributes);
  }

  @override
  int get hashCode => product.id.hashCode ^ selectedAttributes.hashCode;

  bool _mapsEqual(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }
}

class Cart {
  final List<CartItem> items;
  final String? couponCode;
  final double discount;

  Cart({
    this.items = const [],
    this.couponCode,
    this.discount = 0,
  });

  double get subtotal => items.fold(0, (total, item) => total + item.total);
  double get total => subtotal - discount;
  int get itemCount => items.fold(0, (count, item) => count + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? discount,
  }) {
    return Cart(
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List? ?? [])
          .map((item) => CartItem.fromJson(item))
          .toList(),
      couponCode: json['coupon_code'],
      discount: double.parse(json['discount']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'coupon_code': couponCode,
      'discount': discount,
    };
  }
}