import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/src/core/database/app_database.dart';
import 'lib/src/features/menu/data/datasources/menu_local_data_source.dart';
import 'lib/src/features/menu/data/models/product_model.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    final db = AppDatabase.instance;
    final menuSource = MenuLocalDataSource(db);

    final products = await menuSource.getProducts();
    final firstProd = products.first;
    print('First product: ${firstProd.id} - ${firstProd.name}');

    final updatedModel = ProductModel(
      id: firstProd.id,
      categoryId: firstProd.categoryId,
      name: firstProd.name + ' Edited',
      description: firstProd.description,
      price: firstProd.price + 1,
      available: !firstProd.available,
      imagePath: firstProd.imagePath,
    );

    await menuSource.updateProduct(updatedModel);
    print('Product updated successfully!');

    final fetchedAgain = await menuSource.getProducts();
    final check = fetchedAgain.firstWhere((p) => p.id == firstProd.id);
    print('Fetched: ${check.name}, price: ${check.price}, available: ${check.available}');
    
    // restore
    await menuSource.updateProduct(firstProd);

    exit(0);
  } catch (e, stack) {
    print('Error: $e');
    exit(1);
  }
}
