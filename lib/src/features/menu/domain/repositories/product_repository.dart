import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts();

  Future<Product> createProduct(Product product);

  Future<void> updateProduct(Product product);

  Future<void> deleteProduct(int id);

  /// Replaces all modifiers for [productId] with [modifiers].
  Future<void> saveModifiers(int productId, List<ProductModifier> modifiers);
}
