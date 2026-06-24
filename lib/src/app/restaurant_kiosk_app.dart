import 'package:flutter/material.dart';

import '../features/menu/presentation/widgets/admin_scaffold.dart';
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
      home: const AdminScaffold(),
    );
  }
}
