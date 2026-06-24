import '../../domain/entities/product.dart';

class ProductModel {
  const ProductModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    this.imagePath,
  });

  final int? id;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String? imagePath;

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      categoryId: product.categoryId,
      name: product.name,
      description: product.description,
      price: product.price,
      available: product.available,
      imagePath: product.imagePath,
    );
  }

  factory ProductModel.fromMap(Map<String, Object?> map) {
    return ProductModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      available: (map['available'] as int) == 1,
      imagePath: map['image_path'] as String?,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      available: available,
      imagePath: imagePath,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'available': available ? 1 : 0,
      'image_path': imagePath,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
