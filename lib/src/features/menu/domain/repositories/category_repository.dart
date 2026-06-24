import '../entities/menu_category.dart';

abstract interface class CategoryRepository {
  Future<List<MenuCategory>> getCategories();

  Future<MenuCategory> createCategory(MenuCategory category);

  Future<void> updateCategory(MenuCategory category);

  Future<void> deleteCategory(int id);
}
