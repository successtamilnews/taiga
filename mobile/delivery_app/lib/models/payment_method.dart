class PaymentMethod {
  final String id;
  final String type;
  final String name;
  final String displayName;
  final Map<String, dynamic>? details;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.displayName,
    this.details,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      details: json['details'],
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'display_name': displayName,
      'details': details,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods for different payment method types
  String get cardLastFour {
    if (type == 'card' && details?['last_four'] != null) {
      return details!['last_four'];
    }
    return '';
  }

  String get cardBrand {
    if (type == 'card' && details?['brand'] != null) {
      return details!['brand'];
    }
    return '';
  }

  String get walletProvider {
    if (type == 'wallet' && details?['provider'] != null) {
      return details!['provider'];
    }
    return '';
  }

  double get walletBalance {
    if (type == 'wallet' && details?['balance'] != null) {
      return (details!['balance'] as num).toDouble();
    }
    return 0.0;
  }

  String get formattedDisplayName {
    switch (type) {
      case 'card':
        return '$cardBrand •••• $cardLastFour';
      case 'google_pay':
        return 'Google Pay';
      case 'apple_pay':
        return 'Apple Pay';
      case 'sampath_bank':
        return 'Sampath Bank IPG';
      case 'wallet':
        return 'Taiga Wallet';
      default:
        return displayName;
    }
  }

  String get iconAsset {
    switch (type) {
      case 'card':
        return _getCardIcon(cardBrand);
      case 'google_pay':
        return 'assets/icons/google_pay.png';
      case 'apple_pay':
        return 'assets/icons/apple_pay.png';
      case 'sampath_bank':
        return 'assets/icons/sampath_bank.png';
      case 'wallet':
        return 'assets/icons/wallet.png';
      default:
        return 'assets/icons/payment.png';
    }
  }

  String _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'assets/icons/visa.png';
      case 'mastercard':
        return 'assets/icons/mastercard.png';
      case 'amex':
        return 'assets/icons/amex.png';
      default:
        return 'assets/icons/card.png';
    }
  }

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? name,
    String? displayName,
    Map<String, dynamic>? details,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentMethod &&
        other.id == id &&
        other.type == type &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        name.hashCode;
  }

  @override
  String toString() {
    return 'PaymentMethod(id: $id, type: $type, name: $name, displayName: $displayName)';
  }
}