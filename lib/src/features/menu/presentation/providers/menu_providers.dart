import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/local_image_storage.dart';
import '../../data/datasources/menu_local_data_source.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/product_repository.dart';

final menuLocalDataSourceProvider = Provider<MenuLocalDataSource>((ref) {
  return MenuLocalDataSource(ref.watch(appDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(menuLocalDataSourceProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(menuLocalDataSourceProvider));
});

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<MenuCategory>>(
      CategoriesController.new,
    );

final productsControllerProvider =
    AsyncNotifierProvider<ProductsController, List<Product>>(
      ProductsController.new,
    );

class CategoriesController extends AsyncNotifier<List<MenuCategory>> {
  late final CategoryRepository _repository;

  @override
  Future<List<MenuCategory>> build() {
    _repository = ref.watch(categoryRepositoryProvider);
    return _repository.getCategories();
  }

  Future<void> saveCategory({
    MenuCategory? category,
    required String name,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) {
      throw ArgumentError('Category name is required.');
    }

    await _runMutation(() async {
      if (category == null) {
        await _repository.createCategory(MenuCategory(name: cleanedName));
        return;
      }

      await _repository.updateCategory(category.copyWith(name: cleanedName));
    });
  }

  Future<void> deleteCategory(MenuCategory category) async {
    final id = category.id;
    if (id == null) {
      return;
    }

    await _runMutation(() => _repository.deleteCategory(id));
  }

  Future<void> _runMutation(Future<void> Function() mutation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await mutation();
      return _repository.getCategories();
    });
  }
}

class ProductsController extends AsyncNotifier<List<Product>> {
  late final ProductRepository _repository;
  late final LocalImageStorage _imageStorage;

  @override
  Future<List<Product>> build() {
    _repository = ref.watch(productRepositoryProvider);
    _imageStorage = ref.watch(localImageStorageProvider);
    return _repository.getProducts();
  }

  Future<void> saveProduct({
    Product? product,
    required int categoryId,
    required String name,
    required String description,
    required double price,
    required bool available,
    String? selectedImagePath,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) {
      throw ArgumentError('Product name is required.');
    }

    if (price < 0) {
      throw ArgumentError('Product price cannot be negative.');
    }

    await _runMutation(() async {
      var imagePath = product?.imagePath;
      if (selectedImagePath != null && selectedImagePath != imagePath) {
        imagePath = await _imageStorage.saveProductImage(selectedImagePath);
      }

      final savedProduct = Product(
        id: product?.id,
        categoryId: categoryId,
        name: cleanedName,
        description: description.trim(),
        price: price,
        available: available,
        imagePath: imagePath,
      );

      if (product == null) {
        await _repository.createProduct(savedProduct);
        return;
      }

      await _repository.updateProduct(savedProduct);
    });
  }

  Future<void> deleteProduct(Product product) async {
    final id = product.id;
    if (id == null) {
      return;
    }

    await _runMutation(() => _repository.deleteProduct(id));
  }

  Future<void> _runMutation(Future<void> Function() mutation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await mutation();
      return _repository.getProducts();
    });
  }
}
