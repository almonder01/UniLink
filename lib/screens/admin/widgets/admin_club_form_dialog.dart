import 'package:flutter/material.dart';

class AdminClubFormResult {
  final String name;
  final String category;
  final String description;

  const AdminClubFormResult({
    required this.name,
    required this.category,
    required this.description,
  });
}

class AdminClubFormDialog extends StatefulWidget {
  final Map<String, dynamic>? club;
  final List<String> categories;

  const AdminClubFormDialog({
    super.key,
    required this.categories,
    this.club,
  });

  @override
  State<AdminClubFormDialog> createState() => _AdminClubFormDialogState();
}

class _AdminClubFormDialogState extends State<AdminClubFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descriptionCtrl;

  bool get _isEditing => widget.club != null;

  @override
  void initState() {
    super.initState();
    final club = widget.club;
    _nameCtrl = TextEditingController(text: club?['name'] as String? ?? '');
    _categoryCtrl = TextEditingController(
      text: club?['category'] as String? ?? 'General',
    );
    _descriptionCtrl = TextEditingController(
      text: club?['description'] as String? ?? '',
    );
    _categoryCtrl.addListener(_onCategoryChanged);
  }

  @override
  void dispose() {
    _categoryCtrl.removeListener(_onCategoryChanged);
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged() {
    if (mounted) setState(() {});
  }

  bool _isKnownCategory(String category) {
    return widget.categories.any(
      (item) => item.toLowerCase() == category.trim().toLowerCase(),
    );
  }

  void _selectCategory(String category) {
    _categoryCtrl.text = category;
    _categoryCtrl.selection = TextSelection.collapsed(
      offset: _categoryCtrl.text.length,
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      AdminClubFormResult(
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty
            ? 'General'
            : _categoryCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = _categoryCtrl.text.trim();

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Club' : 'Create New Club',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Club Name',
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter club name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Choose or write a new category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in widget.categories)
                      ChoiceChip(
                        label: Text(item),
                        selected: category.toLowerCase() == item.toLowerCase(),
                        onSelected: (_) => _selectCategory(item),
                      ),
                    if (category.isNotEmpty && !_isKnownCategory(category))
                      Chip(
                        avatar: const Icon(Icons.add_rounded, size: 16),
                        label: Text('New: $category'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
