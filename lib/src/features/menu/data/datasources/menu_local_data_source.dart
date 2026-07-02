import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/product.dart';
import '../models/menu_category_model.dart';
import '../models/product_model.dart';

class MenuLocalDataSource {
  const MenuLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<MenuCategoryModel>> getCategories() async {
    final database = await _appDatabase.database;
    final rows = await database.query('categories', orderBy: 'name ASC');
    return rows.map(MenuCategoryModel.fromMap).toList();
  }

  Future<MenuCategoryModel> createCategory(MenuCategoryModel category) async {
    final database = await _appDatabase.database;
    final id = await database.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return MenuCategoryModel(id: id, name: category.name);
  }

  Future<void> updateCategory(MenuCategoryModel category) async {
    final database = await _appDatabase.database;
    await database.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> deleteCategory(int id) async {
    final database = await _appDatabase.database;
    final productsCountRows = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM products WHERE category_id = ?',
      [id],
    );
    final products = productsCountRows.first['count'] as int? ?? 0;

    if (products > 0) {
      throw StateError('Delete products in this category before deleting it.');
    }

    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProductModel>> getProducts() async {
    final database = await _appDatabase.database;
    final rows = await database.query('products', orderBy: 'name ASC');
    final modifiersRows = await database.query('product_modifiers');

    // Group modifiers by product_id
    final Map<int, List<ProductModifier>> modifiersMap = {};
    for (final row in modifiersRows) {
      final productId = row['product_id'] as int;
      final modifier = ProductModifier(
        id: row['id'] as int?,
        productId: productId,
        name: row['name'] as String,
        extraPrice: (row['extra_price'] as num).toDouble(),
      );
      modifiersMap.putIfAbsent(productId, () => []).add(modifier);
    }

    return rows.map((row) {
      final productId = row['id'] as int;
      return ProductModel.fromMap(
        row,
        modifiers: modifiersMap[productId] ?? [],
      );
    }).toList();
  }


  Future<ProductModel> createProduct(ProductModel product) async {
    final database = await _appDatabase.database;
    final id = await database.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return ProductModel(
      id: id,
      categoryId: product.categoryId,
      name: product.name,
      description: product.description,
      price: product.price,
      available: product.available,
      imagePath: product.imagePath,
    );
  }

  Future<void> updateProduct(ProductModel product) async {
    final database = await _appDatabase.database;
    await database.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> deleteProduct(int id) async {
    final database = await _appDatabase.database;
    await database.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Replaces all modifiers for [productId] with [modifiers].
  Future<void> saveModifiers(
    int productId,
    List<ProductModifier> modifiers,
  ) async {
    final database = await _appDatabase.database;
    await database.transaction((txn) async {
      // Remove existing modifiers for this product.
      await txn.delete(
        'product_modifiers',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      // Insert new modifiers.
      for (final modifier in modifiers) {
        await txn.insert('product_modifiers', {
          'product_id': productId,
          'name': modifier.name,
          'extra_price': modifier.extraPrice,
        });
      }
    });
  }
}
