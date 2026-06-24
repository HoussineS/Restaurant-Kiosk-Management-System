import 'package:flutter/material.dart';

import '../../domain/entities/menu_category.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key, this.category});

  final MenuCategory? category;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit category' : 'Add category'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Category name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a category name';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(_nameController.text.trim());
  }
}
