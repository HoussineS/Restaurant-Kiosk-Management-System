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
      subtitle: 'Manage menu items, images, prices, availability, and options.',
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
                  final w = constraints.maxWidth;

                  // ── Column count based on available local width ─────────
                  final int crossAxisCount;
                  final double aspectRatio;

                  if (w < 500) {
                    // Single column — wide horizontal card
                    crossAxisCount = 1;
                    aspectRatio = 3.2;
                  } else if (w < 760) {
                    // 2 columns — narrow vertical cards (< 300px each)
                    crossAxisCount = 2;
                    aspectRatio = 0.95;
                  } else if (w < 1050) {
                    // 3 columns — narrow vertical cards
                    crossAxisCount = 3;
                    aspectRatio = 1.0;
                  } else if (w < 1400) {
                    // 3 columns — slightly wider, can use horizontal layout
                    crossAxisCount = 3;
                    aspectRatio = 1.55;
                  } else {
                    // 4 columns — wide horizontal cards
                    crossAxisCount = 4;
                    aspectRatio = 1.6;
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        // Switch to vertical layout for narrow cards (multi-column grids)
        final isNarrow = cardWidth < 300;
        return isNarrow
            ? _VerticalCard(
                product: product,
                categoryName: categoryName,
                onEdit: onEdit,
                onDelete: onDelete,
                cardWidth: cardWidth,
              )
            : _HorizontalCard(
                product: product,
                categoryName: categoryName,
                onEdit: onEdit,
                onDelete: onDelete,
                cardWidth: cardWidth,
              );
      },
    );
  }
}

// ─── Horizontal card (image left, content right) — used for wide cards ────────

class _HorizontalCard extends StatelessWidget {
  const _HorizontalCard({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.cardWidth,
  });

  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    // Image occupies ~35% of card width, capped at 140px
    final imageWidth = (cardWidth * 0.35).clamp(80.0, 140.0);
    final isCompact = cardWidth < 420;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: imageWidth,
            child: _ProductImage(
              imagePath: product.imagePath,
              productName: product.name,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 10 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Top: name + chip ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _AvailabilityChip(available: product.available),
                    ],
                  ),

                  // ── Middle: category + description ─────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (product.modifiers.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.tune,
                              size: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${product.modifiers.length} supplement${product.modifiers.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      if (!isCompact && product.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),

                  // ── Bottom: price + action buttons ─────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.price.toStringAsFixed(2)} TND',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton.filledTonal(
                          padding: EdgeInsets.zero,
                          tooltip: 'Edit',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton.filledTonal(
                          padding: EdgeInsets.zero,
                          tooltip: 'Delete',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 15),
                        ),
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

// ─── Vertical card (image top, content bottom) — used for narrow cards ────────

class _VerticalCard extends StatelessWidget {
  const _VerticalCard({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.cardWidth,
  });

  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image (fixed height fraction of card) ──────────────────────
          Expanded(
            flex: 5,
            child: _ProductImage(
              imagePath: product.imagePath,
              productName: product.name,
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name + chip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          _AvailabilityChip(available: product.available),
                        ],
                      ),
                    ],
                  ),

                  // Price + buttons
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.price.toStringAsFixed(2)} TND',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton.filledTonal(
                          padding: EdgeInsets.zero,
                          tooltip: 'Edit',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 13),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton.filledTonal(
                          padding: EdgeInsets.zero,
                          tooltip: 'Delete',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 13),
                        ),
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

// ─── Product Image ─────────────────────────────────────────────────────────────

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
        child: Center(
          child: Icon(
            Icons.fastfood,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (path == null || path.isEmpty) return placeholder();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }

    final file = File(path);
    if (!file.existsSync()) return placeholder();

    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}

// ─── Availability chip ─────────────────────────────────────────────────────────

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      label: Text(
        available ? 'Active' : 'Hidden',
        style: const TextStyle(fontSize: 10),
      ),
      avatar: Icon(
        available ? Icons.check_circle : Icons.pause_circle_outline,
        size: 12,
      ),
      backgroundColor: available
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }
}
