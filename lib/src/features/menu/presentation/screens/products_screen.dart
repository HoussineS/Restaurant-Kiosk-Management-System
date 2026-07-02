import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_category.dart';
import '../../domain/entities/product.dart';
import '../providers/menu_providers.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_panel.dart';
import '../widgets/product_form_dialog.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsControllerProvider);
    final categoriesState = ref.watch(categoriesControllerProvider);

    return AdminPageLayout(
      title: 'Product Management',
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'products_fab',
        onPressed: categoriesState.maybeWhen(
          data: (categories) => categories.isEmpty
              ? null
              : () => _openProductDialog(context, ref, categories),
          orElse: () => null,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
      child: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorPanel(
          message: error.toString(),
          onRetry: () => ref.invalidate(categoriesControllerProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'Create a category first',
              message: 'Products need a category before they can be added.',
            );
          }

          return productsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorPanel(
              message: error.toString(),
              onRetry: () => ref.invalidate(productsControllerProvider),
            ),
            data: (products) {
              if (products.isEmpty) {
                return const EmptyState(
                  icon: Icons.fastfood_outlined,
                  title: 'No products yet',
                  message:
                      'Add menu items with prices, images, and availability.',
                );
              }

              final categoryNames = {
                for (final category in categories) category.id: category.name,
              };

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 920;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.65 : 1.35,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        categoryName:
                            categoryNames[product.categoryId] ?? 'Unknown',
                        onEdit: () => _openProductDialog(
                          context,
                          ref,
                          categories,
                          product: product,
                        ),
                        onDelete: () => _confirmDelete(context, ref, product),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openProductDialog(
    BuildContext context,
    WidgetRef ref,
    List<MenuCategory> categories, {
    Product? product,
  }) async {
    final result = await showDialog<ProductFormResult>(
      context: context,
      builder: (_) =>
          ProductFormDialog(categories: categories, product: product),
    );

    if (result == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(productsControllerProvider.notifier)
          .saveProduct(
            product: product,
            categoryId: result.categoryId,
            name: result.name,
            description: result.description,
            price: result.price,
            available: result.available,
            selectedImagePath: result.selectedImagePath,
            modifiers: result.modifiers
                .map(
                  (m) => ProductModifier(
                    productId: product?.id ?? 0,
                    name: m.name,
                    extraPrice: m.extraPrice,
                  ),
                )
                .toList(),
          );
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Product saved.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, error.toString());
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(productsControllerProvider.notifier)
          .deleteProduct(product);
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Product deleted.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, error.toString());
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _ProductImage(
              imagePath: product.imagePath,
              productName: product.name,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AvailabilityChip(available: product.available),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (product.modifiers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.modifiers.length} supplement${product.modifiers.length == 1 ? '' : 's'}',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      product.description.isEmpty
                          ? 'No description'
                          : product.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.price.toStringAsFixed(2)} TND',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Edit product',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Delete product',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imagePath, required this.productName});

  final String? imagePath;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    Widget placeholder() {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.fastfood,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (path == null || path.isEmpty) {
      return placeholder();
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      return placeholder();
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(available ? 'Active' : 'Hidden'),
      avatar: Icon(
        available ? Icons.check_circle : Icons.pause_circle_outline,
        size: 16,
      ),
      backgroundColor: available
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }
}
