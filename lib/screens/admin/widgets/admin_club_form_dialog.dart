import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/identity_avatar.dart';

class AdminClubFormResult {
  final String name;
  final String category;
  final String description;
  final String logoColor;
  final String logoImageBase64;
  final bool showLogoBackground;

  const AdminClubFormResult({
    required this.name,
    required this.category,
    required this.description,
    required this.logoColor,
    required this.logoImageBase64,
    required this.showLogoBackground,
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
  final _picker = ImagePicker();

  String _logoColor = 'FF6366F1';
  Uint8List? _logoImage;
  bool _showLogoBackground = true;

  static const _logoColors = [
    'FF6366F1',
    'FF14B8A6',
    'FFF97316',
    'FF22C55E',
    'FFA855F7',
    'FFEF4444',
  ];

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
    final color = club?['logo_color'] as String?;
    _logoColor = color != null && color.length == 8 ? color : 'FF6366F1';
    _logoImage = _decode(club?['logo_image_base64'] as String?);
    _showLogoBackground = club?['show_logo_background'] as bool? ?? true;
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

  Uint8List? _decode(String? image) {
    if (image == null || image.isEmpty) return null;
    try {
      return base64Decode(image);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickLogoImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 78,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _logoImage = bytes);
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
        logoColor: _logoColor,
        logoImageBase64:
            _logoImage == null ? '' : base64Encode(_logoImage!),
        showLogoBackground: _showLogoBackground,
      ),
    );
  }

  Widget _logoSection() {
    final color = Color(int.parse(_logoColor, radix: 16));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Club Logo',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ClubAvatar(
              color: color,
              logoBase64:
                  _logoImage == null ? null : base64Encode(_logoImage!),
              showBackground: _showLogoBackground,
              size: 70,
              borderRadius: 18,
              onTap: _pickLogoImage,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _pickLogoImage,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label:
                        Text(_logoImage == null ? 'Add logo' : 'Change logo'),
                  ),
                  if (_logoImage != null)
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _logoImage = null),
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Remove logo',
                    ),
                ],
              ),
            ),
          ],
        ),
        SwitchListTile(
          value: _showLogoBackground,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Show logo background',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          onChanged: (value) => setState(() => _showLogoBackground = value),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final colorHex in _logoColors)
              _AdminLogoColorDot(
                color: Color(int.parse(colorHex, radix: 16)),
                selected: _logoColor == colorHex,
                onTap: () => setState(() => _logoColor = colorHex),
              ),
          ],
        ),
      ],
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
              _logoSection(),
              const SizedBox(height: 16),
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

class _AdminLogoColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AdminLogoColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white.withValues(alpha: 0.8),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
