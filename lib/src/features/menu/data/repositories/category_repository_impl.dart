import '../../domain/entities/menu_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/menu_local_data_source.dart';
import '../models/menu_category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._localDataSource);

  final MenuLocalDataSource _localDataSource;

  @override
  Future<List<MenuCategory>> getCategories() async {
    final categories = await _localDataSource.getCategories();
    return categories.map((category) => category.toEntity()).toList();
  }

  @override
  Future<MenuCategory> createCategory(MenuCategory category) async {
    final createdCategory = await _localDataSource.createCategory(
      MenuCategoryModel.fromEntity(category),
    );
    return createdCategory.toEntity();
  }

  @override
  Future<void> updateCategory(MenuCategory category) {
    return _localDataSource.updateCategory(
      MenuCategoryModel.fromEntity(category),
    );
  }

  @override
  Future<void> deleteCategory(int id) {
    return _localDataSource.deleteCategory(id);
  }
}
