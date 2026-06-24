import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalImageStorage {
  Future<String> saveProductImage(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw ArgumentError('Selected image file does not exist.');
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final imageDirectory = Directory(
      p.join(supportDirectory.path, 'product_images'),
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final extension = p.extension(sourcePath);
    final fileName =
        'product_${DateTime.now().microsecondsSinceEpoch}$extension';
    final savedFile = await sourceFile.copy(
      p.join(imageDirectory.path, fileName),
    );

    return savedFile.path;
  }
}
