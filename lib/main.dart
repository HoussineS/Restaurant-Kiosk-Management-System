import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/restaurant_kiosk_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await windowManager.ensureInitialized();

  // Set a sensible minimum size so the layout never breaks, but allow
  // free resizing so the responsive breakpoints in responsive_layout.dart
  // can adapt automatically as the window is dragged.
  const WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(640, 480),
    size: Size(1280, 800),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.maximize();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: RestaurantKioskApp()));
}
