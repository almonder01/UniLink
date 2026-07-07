import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club.dart';
import '../../models/media_asset.dart';
import '../../models/post.dart';
import '../../services/cloudinary_upload_service.dart';
import '../../services/database_service.dart';
import '../../services/media_asset_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/media_attachment_fields.dart';
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
  final _youtubeCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _audioUrlCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryUploadService();
  final _mediaAssets = MediaAssetService();

  bool _saving = false;
  PlatformFile? _pendingVideoFile;
  PlatformFile? _pendingAudioFile;
  String _videoType = 'youtube';
  String _audioType = 'audio';
  String _selectedColor = 'FF6366F1';
  Uint8List? _coverImage;
  final List<Uint8List> _additionalImages = [];
  List<MediaAsset> _savedMediaAssets = [];

  bool get _isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    _youtubeCtrl.addListener(() => setState(() {}));
    _videoUrlCtrl.addListener(() => setState(() {}));
    _audioUrlCtrl.addListener(() => setState(() {}));
    _loadSavedMediaAssets();
    final post = widget.existingPost;
    if (post == null) return;

    _titleCtrl.text = post.title;
    _bodyCtrl.text = post.description;
    _youtubeCtrl.text = post.youtubeUrl ?? '';
    _videoUrlCtrl.text = post.videoUrl ?? '';
    _audioUrlCtrl.text = post.audioUrl ?? '';
    _videoType = (post.videoUrl ?? '').trim().isNotEmpty ? 'video' : 'youtube';
    _audioType = post.audioType == 'youtube' ? 'youtube' : 'audio';
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
    _youtubeCtrl.dispose();
    _videoUrlCtrl.dispose();
    _audioUrlCtrl.dispose();
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

  Future<void> _loadSavedMediaAssets() async {
    final assets = await _mediaAssets.getAssetsForClub(widget.club.id);
    if (mounted) setState(() => _savedMediaAssets = assets);
  }

  List<MediaAsset> get _savedVideos =>
      _savedMediaAssets.where((asset) => asset.isVideo).toList();

  List<MediaAsset> get _savedAudio =>
      _savedMediaAssets.where((asset) => asset.isAudio).toList();

  void _selectVideoAsset(MediaAsset asset) {
    setState(() {
      _pendingVideoFile = null;
      if (asset.sourceType == 'youtube') {
        _videoType = 'youtube';
        _youtubeCtrl.text = asset.url;
        _videoUrlCtrl.clear();
      } else {
        _videoType = 'video';
        _videoUrlCtrl.text = asset.url;
        _youtubeCtrl.clear();
      }
    });
    _showLoadedMessage('Video loaded from media library');
  }

  void _selectAudioAsset(MediaAsset asset) {
    setState(() {
      _pendingAudioFile = null;
      _audioType = asset.sourceType == 'youtube' ? 'youtube' : 'audio';
      _audioUrlCtrl.text = asset.url;
    });
    _showLoadedMessage('Music loaded from media library');
  }

  void _showLoadedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _rememberMedia({
    required String title,
    required String youtubeUrl,
    required String videoUrl,
    required String audioUrl,
  }) async {
    try {
      await _mediaAssets.saveFromUrl(
        clubId: widget.club.id,
        name: '$title video',
        url: youtubeUrl,
        mediaKind: 'video',
        sourceType: 'youtube',
        createdBy: widget.club.managerId,
      );
      await _mediaAssets.saveFromUrl(
        clubId: widget.club.id,
        name: '$title video',
        url: videoUrl,
        mediaKind: 'video',
        sourceType: 'video',
        createdBy: widget.club.managerId,
      );
      await _mediaAssets.saveFromUrl(
        clubId: widget.club.id,
        name: '$title music',
        url: audioUrl,
        mediaKind: 'audio',
        sourceType: _audioType,
        createdBy: widget.club.managerId,
      );
      await _loadSavedMediaAssets();
    } catch (_) {
      // Media library indexing should not block publishing the post.
    }
  }

  Future<void> _uploadVideo() async {
    final picked = await FilePicker.pickFiles(type: FileType.video);
    if (picked == null || picked.files.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _pendingVideoFile = picked.files.single;
      _videoType = 'video';
    });
  }

  Future<void> _chooseAudio() async {
    final picked = await FilePicker.pickFiles(type: FileType.audio);
    if (picked == null || picked.files.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _pendingAudioFile = picked.files.single;
      _audioType = 'audio';
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final coverImageBase64 =
        _coverImage == null ? null : base64Encode(_coverImage!);
    final photoBase64List =
        _additionalImages.map((bytes) => base64Encode(bytes)).toList();
    final youtubeUrl = _videoType == 'youtube' ? _youtubeCtrl.text.trim() : '';
    var videoUrl = _videoType == 'video' ? _videoUrlCtrl.text.trim() : '';
    var audioUrl = _audioUrlCtrl.text.trim();

    try {
      if (_pendingVideoFile != null && _videoType == 'video') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading video...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        final upload = await _cloudinary.uploadPlatformFile(_pendingVideoFile!);
        if (!mounted) return;
        videoUrl = upload.secureUrl;
      }
      if (_pendingAudioFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading audio...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        final upload = await _cloudinary.uploadPlatformFile(_pendingAudioFile!);
        if (!mounted) return;
        audioUrl = upload.secureUrl;
      }
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
        youtubeUrl: youtubeUrl.isEmpty ? null : youtubeUrl,
        videoUrl: videoUrl.isEmpty ? null : videoUrl,
        videoType: 'video',
        audioUrl: audioUrl.isEmpty ? null : audioUrl,
        audioType: _audioType,
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
      await _rememberMedia(
        title: post.title,
        youtubeUrl: youtubeUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
      );
      _youtubeCtrl.text = youtubeUrl;
      _videoUrlCtrl.text = videoUrl;
      _audioUrlCtrl.text = audioUrl;
      _pendingVideoFile = null;
      _pendingAudioFile = null;

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
              MediaAttachmentFields(
                title: 'Media',
                subtitle: 'Add one video source and optional background music.',
                youtubeVideoController: _youtubeCtrl,
                directVideoController: _videoUrlCtrl,
                videoType: _videoType,
                onVideoTypeChanged: (value) =>
                    setState(() => _videoType = value),
                onPickVideo: _uploadVideo,
                pendingVideoName: _pendingVideoFile?.name,
                videoAssets: _savedVideos,
                selectedVideoUrl: _videoType == 'youtube'
                    ? _youtubeCtrl.text.trim()
                    : _videoUrlCtrl.text.trim(),
                onVideoAssetSelected: _selectVideoAsset,
                audioController: _audioUrlCtrl,
                audioType: _audioType,
                onAudioTypeChanged: (value) =>
                    setState(() => _audioType = value),
                onPickAudio: _chooseAudio,
                pendingAudioName: _pendingAudioFile?.name,
                audioAssets: _savedAudio,
                selectedAudioUrl: _audioUrlCtrl.text.trim(),
                onAudioAssetSelected: _selectAudioAsset,
                videoPreviewTitle: 'Post video preview',
                audioPreviewTitle: 'Post music preview',
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
