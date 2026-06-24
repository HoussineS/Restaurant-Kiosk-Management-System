import '../../domain/entities/menu_category.dart';

class MenuCategoryModel {
  const MenuCategoryModel({this.id, required this.name});

  final int? id;
  final String name;

  factory MenuCategoryModel.fromEntity(MenuCategory category) {
    return MenuCategoryModel(id: category.id, name: category.name);
  }

  factory MenuCategoryModel.fromMap(Map<String, Object?> map) {
    return MenuCategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  MenuCategory toEntity() {
    return MenuCategory(id: id, name: name);
  }

  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, 'name': name};
  }
}
