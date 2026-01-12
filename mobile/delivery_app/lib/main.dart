import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/delivery/delivery_dashboard_screen.dart';
import 'screens/orders/delivery_orders_screen.dart';
import 'screens/orders/order_details_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/profile/delivery_profile_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider<DeliveryProvider>(
          create: (_) => DeliveryProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: '${AppConstants.appName} - Delivery',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: SplashScreen.routeName,
        routes: {
          SplashScreen.routeName: (context) => const SplashScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          DeliveryDashboardScreen.routeName: (context) => const DeliveryDashboardScreen(),
          DeliveryOrdersScreen.routeName: (context) => const DeliveryOrdersScreen(),
          MapScreen.routeName: (context) => const MapScreen(),
          DeliveryProfileScreen.routeName: (context) => const DeliveryProfileScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const DeliveryDashboardScreen(),
          );
        },
      ),
    );
  }
}