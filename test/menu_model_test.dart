import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_kiosk_management_system/src/features/menu/domain/entities/menu_category.dart';
import 'package:restaurant_kiosk_management_system/src/features/menu/domain/entities/product.dart';

void main() {
  test('menu category copyWith keeps unchanged values', () {
    const category = MenuCategory(id: 1, name: 'Burgers');

    final updatedCategory = category.copyWith(name: 'Sandwiches');

    expect(updatedCategory.id, 1);
    expect(updatedCategory.name, 'Sandwiches');
  });

  test('product copyWith updates selected values', () {
    const product = Product(
      id: 1,
      categoryId: 2,
      name: 'Classic Burger',
      description: 'Beef patty with sauce',
      price: 9.5,
      available: true,
    );

    final updatedProduct = product.copyWith(price: 10.0, available: false);

    expect(updatedProduct.id, 1);
    expect(updatedProduct.categoryId, 2);
    expect(updatedProduct.price, 10.0);
    expect(updatedProduct.available, false);
  });
}
