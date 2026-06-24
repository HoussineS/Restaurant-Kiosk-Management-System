class Product {
  const Product({
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

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    double? price,
    bool? available,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      available: available ?? this.available,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
