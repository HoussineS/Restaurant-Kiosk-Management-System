import 'package:flutter/material.dart';

import '../features/kiosk/presentation/screens/customer_kiosk_screen.dart';
import 'theme/app_theme.dart';

class RestaurantKioskApp extends StatelessWidget {
  const RestaurantKioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Kiosk Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const CustomerKioskScreen(),
    );
  }
}
