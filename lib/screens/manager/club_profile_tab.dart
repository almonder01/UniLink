import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/identity_avatar.dart';
import 'additional_photos_grid.dart';

class ClubProfileTab extends StatefulWidget {
  final ClubModel club;
  final ValueChanged<ClubModel>? onChanged;

  const ClubProfileTab({
    super.key,
    required this.club,
    this.onChanged,
  });

  @override
  State<ClubProfileTab> createState() => _ClubProfileTabState();
}

class _ClubProfileTabState extends State<ClubProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _logoColor = 'FF6366F1';
  Uint8List? _logoImage;
  bool _showLogoBackground = true;
  Uint8List? _clubImage;
  final List<Uint8List> _galleryImages = [];
  bool _saving = false;

  static const _logoColors = [
    'FF6366F1',
    'FF14B8A6',
    'FFF97316',
    'FF22C55E',
    'FFA855F7',
    'FFEF4444',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.club.name;
    _descCtrl.text = widget.club.description;
    _logoColor = widget.club.logoColor;
    _logoImage = _decode(widget.club.logoImageBase64);
    _showLogoBackground = widget.club.showLogoBackground;
    _clubImage = _decode(widget.club.imageBase64);
    _galleryImages.addAll(
      widget.club.galleryBase64List.map(_decode).whereType<Uint8List>(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Uint8List? _decode(String? image) {
    if (image == null || image.isEmpty) return null;
    try {
      return base64Decode(image);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickClubImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 70,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _clubImage = bytes);
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

  Future<void> _pickGalleryImage() async {
    if (_galleryImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 club photos')),
      );
      return;
    }
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 700,
      imageQuality: 68,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _galleryImages.add(bytes));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final updated = ClubModel(
      id: widget.club.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: widget.club.category,
      logoColor: _logoColor,
      logoImageBase64: _logoImage == null ? '' : base64Encode(_logoImage!),
      showLogoBackground: _showLogoBackground,
      imageBase64: _clubImage == null ? '' : base64Encode(_clubImage!),
      galleryBase64List: _galleryImages
          .map((image) => base64Encode(image))
          .toList(growable: false),
      managerId: widget.club.managerId,
      managerName: widget.club.managerName,
      memberCount: widget.club.memberCount,
    );

    try {
      await ClubService().updateClub(updated);
      widget.onChanged?.call(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Club profile updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update club: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logoColor = Color(int.parse(_logoColor, radix: 16));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Club Logo',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClubAvatar(
                            color: logoColor,
                            logoBase64: _logoImage == null
                                ? null
                                : base64Encode(_logoImage!),
                            showBackground: _showLogoBackground,
                            size: 72,
                            borderRadius: 18,
                            onTap: _logoImage == null
                                ? _pickLogoImage
                                : () => showBase64ImagePreview(
                                      context,
                                      data: base64Encode(_logoImage!),
                                    ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: _pickLogoImage,
                                  icon: const Icon(
                                      Icons.add_photo_alternate_rounded),
                                  label: Text(_logoImage == null
                                      ? 'Add logo'
                                      : 'Change logo'),
                                ),
                                if (_logoImage != null)
                                  IconButton.filledTonal(
                                    onPressed: () =>
                                        setState(() => _logoImage = null),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                    tooltip: 'Remove logo',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _showLogoBackground,
                        onChanged: (value) =>
                            setState(() => _showLogoBackground = value),
                        title: const Text(
                          'Show logo background',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Controls the colored shape behind the logo',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_showLogoBackground) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final colorHex in _logoColors)
                              _LogoColorDot(
                                color: Color(int.parse(colorHex, radix: 16)),
                                selected: _logoColor == colorHex,
                                onTap: () =>
                                    setState(() => _logoColor = colorHex),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Club Cover',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Tap the cover to preview it.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_clubImage != null)
                            TextButton.icon(
                              onPressed: () => showBase64ImagePreview(
                                context,
                                data: base64Encode(_clubImage!),
                              ),
                              icon: const Icon(Icons.open_in_full_rounded),
                              label: const Text('Preview'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _clubImage == null
                            ? _pickClubImage
                            : () => showBase64ImagePreview(
                                  context,
                                  data: base64Encode(_clubImage!),
                                ),
                        child: AspectRatio(
                          aspectRatio: 16 / 7,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  logoColor,
                                  Color.lerp(logoColor, Colors.black, 0.35)!,
                                ],
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_clubImage != null)
                                  Image.memory(_clubImage!, fit: BoxFit.cover)
                                else
                                  Icon(
                                    Icons.groups_rounded,
                                    size: 84,
                                    color:
                                        Colors.white.withValues(alpha: 0.18),
                                  ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: GestureDetector(
                                    onTap: _pickClubImage,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.55),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.photo_camera_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Change photo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_clubImage != null)
                                  Positioned(
                                    left: 12,
                                    bottom: 12,
                                    child: IconButton.filledTonal(
                                      onPressed: () =>
                                          setState(() => _clubImage = null),
                                      icon: const Icon(
                                          Icons.delete_outline_rounded),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Club Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Club Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Club name is required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        minLines: 5,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'About Club',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 92),
                            child: Icon(Icons.notes_rounded),
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 10
                                ? 'Write at least 10 characters'
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AdditionalPhotosGrid(
                    images: _galleryImages,
                    onAdd: _pickGalleryImage,
                    onRemoveAt: (index) =>
                        setState(() => _galleryImages.removeAt(index)),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save Club Profile'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LogoColorDot({
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
