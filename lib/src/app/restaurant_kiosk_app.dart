import 'package:flutter/material.dart';

import '../features/menu/presentation/screens/categories_screen.dart';
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
      themeMode: ThemeMode.system,
      home: const CategoriesScreen(),
    );
  }
}
