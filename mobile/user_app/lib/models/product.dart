class Product {
  final int id;
  final String name;
  final String description;
  final String? shortDescription;
  final double price;
  final double? salePrice;
  final String? sku;
  final int stockQuantity;
  final bool inStock;
  final bool featured;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final List<ProductCategory> categories;
  final Vendor vendor;
  final List<ProductAttribute> attributes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.shortDescription,
    required this.price,
    this.salePrice,
    this.sku,
    required this.stockQuantity,
    required this.inStock,
    required this.featured,
    required this.rating,
    required this.reviewCount,
    required this.images,
    required this.categories,
    required this.vendor,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get finalPrice => salePrice ?? price;
  bool get onSale => salePrice != null && salePrice! < price;
  String get mainImage => images.isNotEmpty ? images.first : '';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      shortDescription: json['short_description'],
      price: double.parse(json['price'].toString()),
      salePrice: json['sale_price'] != null 
          ? double.parse(json['sale_price'].toString()) 
          : null,
      sku: json['sku'],
      stockQuantity: json['stock_quantity'],
      inStock: json['in_stock'],
      featured: json['featured'],
      rating: double.parse(json['rating'].toString()),
      reviewCount: json['review_count'],
      images: List<String>.from(json['images'] ?? []),
      categories: (json['categories'] as List)
          .map((cat) => ProductCategory.fromJson(cat))
          .toList(),
      vendor: Vendor.fromJson(json['vendor']),
      attributes: (json['attributes'] as List? ?? [])
          .map((attr) => ProductAttribute.fromJson(attr))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'short_description': shortDescription,
      'price': price,
      'sale_price': salePrice,
      'sku': sku,
      'stock_quantity': stockQuantity,
      'in_stock': inStock,
      'featured': featured,
      'rating': rating,
      'review_count': reviewCount,
      'images': images,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'vendor': vendor.toJson(),
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final String? description;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.description,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      image: json['image'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'description': description,
    };
  }
}

class ProductAttribute {
  final String name;
  final String value;
  final String? type;

  ProductAttribute({
    required this.name,
    required this.value,
    this.type,
  });

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      name: json['name'],
      value: json['value'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'type': type,
    };
  }
}

class Vendor {
  final int id;
  final String name;
  final String? description;
  final String? logo;
  final String? banner;
  final double rating;
  final int reviewCount;
  final bool verified;

  Vendor({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.banner,
    required this.rating,
    required this.reviewCount,
    required this.verified,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      logo: json['logo'],
      banner: json['banner'],
      rating: double.parse(json['rating'].toString()),
      reviewCount: json['review_count'] ?? 0,
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'banner': banner,
      'rating': rating,
      'review_count': reviewCount,
      'verified': verified,
    };
  }
}