import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club.dart';
import '../../models/post.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import 'additional_photos_grid.dart';
import 'color_swatch_picker.dart';
import 'cover_photo_picker.dart';

class CreatePostScreen extends StatefulWidget {
  final ClubModel club;
  final PostModel? existingPost;

  const CreatePostScreen({
    super.key,
    required this.club,
    this.existingPost,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _saving = false;
  String _selectedColor = 'FF6366F1';
  Uint8List? _coverImage;
  final List<Uint8List> _additionalImages = [];

  bool get _isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    final post = widget.existingPost;
    if (post == null) return;

    _titleCtrl.text = post.title;
    _bodyCtrl.text = post.description;
    _selectedColor = post.coverColor;
    _coverImage = _decodeImage(post.coverImageBase64);
    _additionalImages.addAll(
      post.photoBase64List.map(_decodeImage).whereType<Uint8List>().take(5),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Uint8List? _decodeImage(String? image) {
    if (image == null || image.isEmpty) return null;
    try {
      return base64Decode(image);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickCover() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 70,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _coverImage = bytes);
  }

  Future<void> _pickAdditional() async {
    if (_additionalImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 additional photos')),
      );
      return;
    }
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      imageQuality: 65,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _additionalImages.add(bytes));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final coverImageBase64 =
        _coverImage == null ? null : base64Encode(_coverImage!);
    final photoBase64List =
        _additionalImages.map((bytes) => base64Encode(bytes)).toList();

    try {
      final existing = widget.existingPost;
      final post = PostModel(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        description: _bodyCtrl.text.trim(),
        clubId: existing?.clubId ?? widget.club.id,
        clubName: existing?.clubName ?? widget.club.name,
        clubLogoColor: existing?.clubLogoColor ?? widget.club.logoColor,
        clubLogoImageBase64:
            existing?.clubLogoImageBase64 ?? widget.club.logoImageBase64,
        clubShowLogoBackground:
            existing?.clubShowLogoBackground ?? widget.club.showLogoBackground,
        coverColor: _selectedColor,
        coverImageBase64: coverImageBase64,
        photoBase64List: photoBase64List,
        createdAt: existing?.createdAt ?? DateTime.now(),
        likedUserIds: existing?.likedUserIds ?? const [],
        likeCount: existing?.likeCount ?? 0,
        commentCount: existing?.commentCount ?? 0,
      );

      if (_isEditing) {
        await DatabaseService().updatePost(post);
      } else {
        await DatabaseService().insertPost(post);
        NotificationService()
            .notifyFollowers(
              clubId: widget.club.id,
              title: 'New post from ${widget.club.name}',
              body: post.title,
              type: 'post',
              color: widget.club.logoColor,
              refId: post.id,
            )
            .catchError((_) {});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(_isEditing
                ? 'Post updated successfully!'
                : 'Post published successfully!'),
          ]),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, post);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewColor = Color(int.parse(_selectedColor, radix: 16));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isEditing ? Icons.save_rounded : Icons.publish_rounded,
                      size: 18,
                    ),
              label: Text(
                _saving
                    ? (_isEditing ? 'Saving...' : 'Publishing...')
                    : (_isEditing ? 'Save' : 'Publish'),
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoverPhotoPicker(
                coverImage: _coverImage,
                previewColor: previewColor,
                onTap: _pickCover,
              ),
              const SizedBox(height: 20),
              ColorSwatchPicker(
                selectedColor: _selectedColor,
                onColorSelected: (hex) => setState(() => _selectedColor = hex),
                swatches: ColorSwatchPicker.postSwatches,
                label: 'Post Accent Color',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: 'Post title...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              Divider(color: cs.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: null,
                minLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, height: 1.65),
                decoration: InputDecoration(
                  hintText: 'Write something amazing...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please write at least 10 characters'
                    : null,
              ),
              const SizedBox(height: 20),
              AdditionalPhotosGrid(
                images: _additionalImages,
                onAdd: _pickAdditional,
                onRemoveAt: (index) =>
                    setState(() => _additionalImages.removeAt(index)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
