import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/database_maintenance_service.dart';
import '../services/local_image_storage.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final localImageStorageProvider = Provider<LocalImageStorage>((ref) {
  return LocalImageStorage();
});

final databaseMaintenanceServiceProvider = Provider<DatabaseMaintenanceService>(
  (ref) {
    return DatabaseMaintenanceService(ref.watch(appDatabaseProvider));
  },
);
