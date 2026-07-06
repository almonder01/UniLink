import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/identity_avatar.dart';
import 'additional_photos_grid.dart';

part 'club_profile/club_cover_card.dart';
part 'club_profile/club_details_card.dart';
part 'club_profile/club_gallery_card.dart';
part 'club_profile/club_logo_card.dart';
part 'club_profile/logo_color_dot.dart';

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
    final logoColor = Color(int.parse(_logoColor, radix: 16));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClubLogoCard(
                logoColor: logoColor,
                logoImage: _logoImage,
                showLogoBackground: _showLogoBackground,
                selectedLogoColor: _logoColor,
                logoColors: _logoColors,
                onPickLogoImage: _pickLogoImage,
                onRemoveLogoImage: () => setState(() => _logoImage = null),
                onShowLogoBackgroundChanged: (value) =>
                    setState(() => _showLogoBackground = value),
                onLogoColorChanged: (colorHex) =>
                    setState(() => _logoColor = colorHex),
              ),
        
              const SizedBox(height: 14),
              _ClubCoverCard(
                logoColor: logoColor,
                clubImage: _clubImage,
                onPickClubImage: _pickClubImage,
                onRemoveClubImage: () => setState(() => _clubImage = null),
              ),
        
              const SizedBox(height: 18),
              _ClubDetailsCard(
                nameCtrl: _nameCtrl,
                descCtrl: _descCtrl,
              ),
        
              const SizedBox(height: 18),
              _ClubGalleryCard(
                images: _galleryImages,
                onAdd: _pickGalleryImage,
                onRemoveAt: (index) =>
                    setState(() => _galleryImages.removeAt(index)),
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

