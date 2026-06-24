import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/menu_local_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._localDataSource);

  final MenuLocalDataSource _localDataSource;

  @override
  Future<List<Product>> getProducts() async {
    final products = await _localDataSource.getProducts();
    return products.map((product) => product.toEntity()).toList();
  }

  @override
  Future<Product> createProduct(Product product) async {
    final createdProduct = await _localDataSource.createProduct(
      ProductModel.fromEntity(product),
    );
    return createdProduct.toEntity();
  }

  @override
  Future<void> updateProduct(Product product) {
    return _localDataSource.updateProduct(ProductModel.fromEntity(product));
  }

  @override
  Future<void> deleteProduct(int id) {
    return _localDataSource.deleteProduct(id);
  }
}
