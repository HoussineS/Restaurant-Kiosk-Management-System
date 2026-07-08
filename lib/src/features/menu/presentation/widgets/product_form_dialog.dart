import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/menu_category.dart';
import '../../domain/entities/product.dart';

// ── Result object ──────────────────────────────────────────────────────────

class ProductFormResult {
  const ProductFormResult({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    this.selectedImagePath,
    this.modifiers = const [],
  });

  final int categoryId;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String? selectedImagePath;
  final List<ModifierDraft> modifiers;
}

// ── Public draft model (no productId needed at form level) ────────────────

class ModifierDraft {
  ModifierDraft({this.name = '', this.extraPrice = 0.0});

  String name;
  double extraPrice;
}

// ── Dialog widget ──────────────────────────────────────────────────────────

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({super.key, required this.categories, this.product});

  final List<MenuCategory> categories;
  final Product? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late int _categoryId;
  late bool _available;
  String? _selectedImagePath;

  // Each modifier draft owns its own controllers so they stay in sync.
  final List<_ModifierRow> _modifierRows = [];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _categoryId = product?.categoryId ?? widget.categories.first.id!;
    _available = product?.available ?? true;
    _selectedImagePath = product?.imagePath;

    // Pre-populate existing modifiers when editing.
    if (product != null) {
      for (final m in product.modifiers) {
        _modifierRows.add(_ModifierRow(name: m.name, extraPrice: m.extraPrice));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (final row in _modifierRows) {
      row.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _addModifierRow() {
    setState(() => _modifierRows.add(_ModifierRow()));
  }

  void _removeModifierRow(int index) {
    setState(() {
      _modifierRows[index].dispose();
      _modifierRows.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _selectedImagePath = path);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final modifiers = _modifierRows
        .map(
          (row) => ModifierDraft(
            name: row.nameController.text.trim(),
            extraPrice: double.tryParse(row.priceController.text) ?? 0.0,
          ),
        )
        .toList();

    Navigator.of(context).pop(
      ProductFormResult(
        categoryId: _categoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        available: _available,
        selectedImagePath: _selectedImagePath,
        modifiers: modifiers,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(isEditing ? 'Edit product' : 'Add product'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Core product fields ───────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id!,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _categoryId = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Price (TND)'),
                  validator: (value) {
                    final price = double.tryParse(value ?? '');
                    if (price == null) {
                      return 'Enter a valid price';
                    }
                    if (price < 0) {
                      return 'Price cannot be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _available,
                  title: const Text('Available for ordering'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _available = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose image'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedImagePath == null
                            ? 'No image selected'
                            : _selectedImagePath!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),

                // ── Supplements / Modifiers section ───────────────────────
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.tune, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Supplements / Options',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addModifierRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_modifierRows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No supplements added. Tap "Add" to create one.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _modifierRows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final row = _modifierRows[index];
                      return _ModifierRowWidget(
                        row: row,
                        index: index,
                        onRemove: () => _removeModifierRow(index),
                        formKey: _formKey,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(isEditing ? Icons.save : Icons.add),
          label: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

// ── Per-row state holder ───────────────────────────────────────────────────

class _ModifierRow {
  _ModifierRow({String name = '', double extraPrice = 0.0})
    : nameController = TextEditingController(text: name),
      priceController = TextEditingController(
        text: extraPrice == 0.0 ? '' : extraPrice.toStringAsFixed(2),
      );

  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

// ── Per-row widget ─────────────────────────────────────────────────────────

class _ModifierRowWidget extends StatelessWidget {
  const _ModifierRowWidget({
    required this.row,
    required this.index,
    required this.onRemove,
    required this.formKey,
  });

  final _ModifierRow row;
  final int index;
  final VoidCallback onRemove;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: row.nameController,
            decoration: InputDecoration(
              labelText: 'Supplement #${index + 1}',
              hintText: 'e.g. Extra cheese',
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a name';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // Extra price field
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: row.priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Extra price',
              hintText: '0.00',
              isDense: true,
            ),
            validator: (value) {
              final price = (value == null || value.trim().isEmpty)
                  ? 0.0
                  : double.tryParse(value);
              if (price == null) {
                return 'Invalid price';
              }
              if (price < 0) {
                return 'Must be ≥ 0';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 4),
        // Remove button
        IconButton(
          tooltip: 'Remove supplement',
          icon: const Icon(Icons.remove_circle_outline),
          color: Theme.of(context).colorScheme.error,
          onPressed: onRemove,
        ),
      ],
    );
  }
}
