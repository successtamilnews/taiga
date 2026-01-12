class AppConstants {
  // App Info
  static const String appName = 'Taiga Ecommerce';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  static const String apiVersion = 'v1';
  static const String apiTimeout = '30'; // seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Image Sizes
  static const int thumbnailSize = 150;
  static const int mediumImageSize = 300;
  static const int largeImageSize = 600;
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Regular Expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  
  static final RegExp phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$'
  );
  
  static final RegExp nameRegex = RegExp(
    r'^[a-zA-Z\s]+$'
  );
  
  // Pricing
  static const String defaultCurrency = 'LKR';
  static const String currencySymbol = 'Rs.';
  static const int decimalPlaces = 2;
  
  // Cart
  static const int maxCartQuantity = 99;
  static const int minOrderAmount = 500; // Rs. 500
  
  // Image Configuration
  static const List<String> allowedImageExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp'
  ];
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(hours: 1);
  static const Duration splashTimeout = Duration(seconds: 3);
  
  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String cartDataKey = 'cart_data';
  static const String wishlistDataKey = 'wishlist_data';
  static const String settingsKey = 'app_settings';
  static const String languageKey = 'app_language';
  static const String themeKey = 'app_theme';
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  
  // Delivery Status
  static const List<String> deliveryStatusList = [
    'pending',
    'confirmed',
    'picked_up',
    'in_transit',
    'delivered',
    'cancelled',
  ];
  
  // Order Status
  static const List<String> orderStatusList = [
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'cash_on_delivery',
    'google_pay',
    'apple_pay',
    'sampath_bank',
    'credit_card',
  ];
  
  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registerSuccessMessage = 'Registration successful!';
  static const String profileUpdateSuccessMessage = 'Profile updated successfully!';
  static const String orderPlacedSuccessMessage = 'Order placed successfully!';
  static const String addedToCartMessage = 'Added to cart!';
  static const String addedToWishlistMessage = 'Added to wishlist!';
  
  // Product Sorting Options
  static const Map<String, String> sortOptions = {
    'newest': 'Newest First',
    'oldest': 'Oldest First',
    'price_low': 'Price: Low to High',
    'price_high': 'Price: High to Low',
    'name_asc': 'Name: A to Z',
    'name_desc': 'Name: Z to A',
    'rating': 'Highest Rated',
    'popularity': 'Most Popular',
  };
  
  // Social Media URLs
  static const String facebookUrl = 'https://facebook.com/taiga';
  static const String twitterUrl = 'https://twitter.com/taiga';
  static const String instagramUrl = 'https://instagram.com/taiga';
  static const String youtubeUrl = 'https://youtube.com/taiga';
  
  // Support
  static const String supportEmail = 'support@taiga.lk';
  static const String supportPhone = '+94123456789';
  static const String termsUrl = 'https://taiga.lk/terms';
  static const String privacyUrl = 'https://taiga.lk/privacy';
  
  // Feature Flags
  static const bool enableSocialLogin = true;
  static const bool enablePushNotifications = true;
  static const bool enableLocationServices = true;
  static const bool enableBiometricAuth = true;
  static const bool enableDarkMode = true;
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'si': 'සිංහල',
    'ta': 'தமிழ்',
  };
  
  static const String defaultLanguage = 'en';
}