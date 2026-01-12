class Order {
  final int id;
  final String orderNumber;
  final User customer;
  final List<OrderItem> items;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final Address? shippingAddress;
  final Address? billingAddress;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderStatusHistory> statusHistory;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.items,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.shippingAddress,
    this.billingAddress,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.statusHistory,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      customer: User.fromJson(json['customer']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['payment_status'],
      ),
      paymentMethod: json['payment_method'] != null 
          ? PaymentMethod.fromJson(json['payment_method'])
          : null,
      shippingAddress: json['shipping_address'] != null 
          ? Address.fromJson(json['shipping_address'])
          : null,
      billingAddress: json['billing_address'] != null 
          ? Address.fromJson(json['billing_address'])
          : null,
      subtotal: double.parse(json['subtotal'].toString()),
      tax: double.parse(json['tax'].toString()),
      shipping: double.parse(json['shipping'].toString()),
      discount: double.parse(json['discount'].toString()),
      total: double.parse(json['total'].toString()),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      statusHistory: (json['status_history'] as List? ?? [])
          .map((history) => OrderStatusHistory.fromJson(history))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer': customer.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString().split('.').last,
      'payment_status': paymentStatus.toString().split('.').last,
      'payment_method': paymentMethod?.toJson(),
      'shipping_address': shippingAddress?.toJson(),
      'billing_address': billingAddress?.toJson(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status_history': statusHistory.map((h) => h.toJson()).toList(),
    };
  }
}

class OrderItem {
  final int id;
  final Product product;
  final int quantity;
  final double price;
  final double total;
  final Map<String, dynamic>? productSnapshot;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.total,
    this.productSnapshot,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      price: double.parse(json['price'].toString()),
      total: double.parse(json['total'].toString()),
      productSnapshot: json['product_snapshot'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'total': total,
      'product_snapshot': productSnapshot,
    };
  }
}

class Address {
  final int? id;
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String? address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String? phone;
  final String? email;

  Address({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    this.phone,
    this.email,
  });

  String get fullName => '$firstName $lastName';
  String get fullAddress => [
    address1,
    if (address2?.isNotEmpty == true) address2,
    city,
    state,
    postcode,
    country,
  ].join(', ');

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      company: json['company'] ?? '',
      address1: json['address_1'],
      address2: json['address_2'],
      city: json['city'],
      state: json['state'],
      postcode: json['postcode'],
      country: json['country'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'phone': phone,
      'email': email,
    };
  }
}

class PaymentMethod {
  final String id;
  final String title;
  final String description;
  final bool enabled;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      enabled: json['enabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'enabled': enabled,
    };
  }
}

class OrderStatusHistory {
  final String status;
  final String? note;
  final DateTime timestamp;

  OrderStatusHistory({
    required this.status,
    this.note,
    required this.timestamp,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: json['status'],
      note: json['note'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
  on_hold
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded
}