import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/local_image_storage.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final localImageStorageProvider = Provider<LocalImageStorage>((ref) {
  return LocalImageStorage();
});
