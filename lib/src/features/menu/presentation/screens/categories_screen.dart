import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_category.dart';
import '../providers/menu_providers.dart';
import 'products_screen.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_panel.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesControllerProvider);

    return AdminPageLayout(
      title: 'Category Management',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Category'),
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
              title: 'No categories yet',
              message: 'Create categories like Burgers, Drinks, and Desserts.',
            );
          }

          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://picsum.photos/seed/${category.name.replaceAll(' ', '')}/100/100',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        child: Text(category.name.characters.first.toUpperCase()),
                      ),
                    ),
                  ),
                  title: Text(category.name),
                  subtitle: Text('Category ID: ${category.id ?? '-'}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Edit category',
                        onPressed: () => _openCategoryDialog(
                          context,
                          ref,
                          category: category,
                        ),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Delete category',
                        onPressed: () => _confirmDelete(context, ref, category),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    MenuCategory? category,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => CategoryFormDialog(category: category),
    );

    if (name == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(categoriesControllerProvider.notifier)
          .saveCategory(category: category, name: name);
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Category saved.');
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
    MenuCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete "${category.name}"?'),
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
          .read(categoriesControllerProvider.notifier)
          .deleteCategory(category);
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Category deleted.');
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
