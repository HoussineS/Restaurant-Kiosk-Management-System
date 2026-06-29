class ProductModifier {
  const ProductModifier({
    this.id,
    required this.productId,
    required this.name,
    required this.extraPrice,
  });

  final int? id;
  final int productId;
  final String name;
  final double extraPrice;

  ProductModifier copyWith({
    int? id,
    int? productId,
    String? name,
    double? extraPrice,
  }) {
    return ProductModifier(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      extraPrice: extraPrice ?? this.extraPrice,
    );
  }
}

class Product {
  const Product({
    this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    this.imagePath,
    this.modifiers = const [],
  });

  final int? id;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String? imagePath;
  final List<ProductModifier> modifiers;

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    double? price,
    bool? available,
    String? imagePath,
    List<ProductModifier>? modifiers,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      available: available ?? this.available,
      imagePath: imagePath ?? this.imagePath,
      modifiers: modifiers ?? this.modifiers,
    );
  }
}
