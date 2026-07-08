import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';

class DatabaseBackupResult {
  const DatabaseBackupResult({
    required this.directoryPath,
    required this.files,
  });

  final String directoryPath;
  final List<File> files;
}

class DatabaseMaintenanceService {
  const DatabaseMaintenanceService(this._database);

  final AppDatabase _database;

  Future<DatabaseBackupResult> backupToDirectory(String directoryPath) async {
    await _database.checkpoint();

    final sourcePath = await _database.databasePath;
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final baseName = 'restaurant_kiosk_backup_$timestamp';
    final copiedFiles = <File>[];

    for (final suffix in const ['', '-wal', '-shm']) {
      final sourceFile = File('$sourcePath$suffix');
      if (!sourceFile.existsSync()) {
        continue;
      }

      final extension = suffix.isEmpty ? '.db' : suffix;
      final targetFile = File(p.join(directoryPath, '$baseName$extension'));
      copiedFiles.add(await sourceFile.copy(targetFile.path));
    }

    return DatabaseBackupResult(
      directoryPath: directoryPath,
      files: copiedFiles,
    );
  }
}
