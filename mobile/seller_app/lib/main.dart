import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/order_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/products/product_management_screen.dart';
import '../screens/orders/seller_orders_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/profile/seller_profile_screen.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<InventoryProvider>(
          create: (_) => InventoryProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) => OrderProvider(),
          update: (context, auth, previousOrders) => 
              previousOrders ?? OrderProvider(),
        ),
      ],
      child: MaterialApp(
        title: '${AppConstants.appName} - Seller',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: SplashScreen.routeName,
        routes: {
          SplashScreen.routeName: (context) => const SplashScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          DashboardScreen.routeName: (context) => const DashboardScreen(),
          ProductManagementScreen.routeName: (context) => const ProductManagementScreen(),
          SellerOrdersScreen.routeName: (context) => const SellerOrdersScreen(),
          AnalyticsScreen.routeName: (context) => const AnalyticsScreen(),
          SellerProfileScreen.routeName: (context) => const SellerProfileScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          );
        },
      ),
    );
  }
}