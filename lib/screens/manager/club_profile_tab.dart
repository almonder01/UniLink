import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/club.dart';
import '../../models/media_asset.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_upload_service.dart';
import '../../services/club_detail_edit_request_service.dart';
import '../../services/club_service.dart';
import '../../services/media_asset_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/identity_avatar.dart';
import '../../widgets/media_auto_option_switch.dart';
import '../../widgets/media_attachment_fields.dart';
import 'additional_photos_grid.dart';

part 'club_profile/club_experience_card.dart';
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
  final _backgroundVideoCtrl = TextEditingController();
  final _musicCtrl = TextEditingController();
  final _featureTitleCtrl = TextEditingController();
  final _featureDescCtrl = TextEditingController();
  final _featureCodeCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryUploadService();
  final _mediaAssets = MediaAssetService();
  final _detailEditRequests = ClubDetailEditRequestService();

  String _logoColor = 'FF6366F1';
  String _backgroundVideoType = 'youtube';
  String _backgroundMusicType = 'audio';
  bool _backgroundVideoAutoOpen = false;
  bool _backgroundMusicAutoPlay = true;
  PlatformFile? _pendingBackgroundVideoFile;
  PlatformFile? _pendingMusicFile;
  Uint8List? _logoImage;
  bool _showLogoBackground = true;
  Uint8List? _clubImage;
  final List<Uint8List> _galleryImages = [];
  List<MediaAsset> _savedMediaAssets = [];
  bool _saving = false;
  bool _detailEditAccessLoading = true;
  bool _canEditDetails = false;
  bool _requestingDetailEdit = false;
  DateTime? _detailEditExpiresAt;
  Timer? _detailEditExpiryTimer;

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
    _backgroundVideoCtrl.addListener(() => setState(() {}));
    _musicCtrl.addListener(() => setState(() {}));
    _loadSavedMediaAssets();
    _nameCtrl.text = widget.club.name;
    _descCtrl.text = widget.club.description;
    _backgroundVideoCtrl.text = widget.club.backgroundVideoUrl ?? '';
    _backgroundVideoType =
        widget.club.backgroundVideoType == 'video' ? 'video' : 'youtube';
    _backgroundVideoAutoOpen = widget.club.backgroundVideoAutoOpen;
    _musicCtrl.text = widget.club.backgroundMusicUrl ?? '';
    _backgroundMusicType =
        widget.club.backgroundMusicType == 'youtube' ? 'youtube' : 'audio';
    _backgroundMusicAutoPlay = widget.club.backgroundMusicAutoPlay;
    _featureTitleCtrl.text = widget.club.featureTitle ?? '';
    _featureDescCtrl.text = widget.club.featureDescription ?? '';
    _featureCodeCtrl.text = widget.club.featureCodeSnippet ?? '';
    _logoColor = widget.club.logoColor;
    _logoImage = _decode(widget.club.logoImageBase64);
    _showLogoBackground = widget.club.showLogoBackground;
    _clubImage = _decode(widget.club.imageBase64);
    _galleryImages.addAll(
      widget.club.galleryBase64List.map(_decode).whereType<Uint8List>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDetailEditAccess();
    });
  }

  @override
  void dispose() {
    _detailEditExpiryTimer?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _backgroundVideoCtrl.dispose();
    _musicCtrl.dispose();
    _featureTitleCtrl.dispose();
    _featureDescCtrl.dispose();
    _featureCodeCtrl.dispose();
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

  Future<void> _loadSavedMediaAssets() async {
    final assets = await _mediaAssets.getAssetsForClub(widget.club.id);
    if (mounted) setState(() => _savedMediaAssets = assets);
  }

  List<MediaAsset> get _savedVideos =>
      _savedMediaAssets.where((asset) => asset.isVideo).toList();

  List<MediaAsset> get _savedAudio =>
      _savedMediaAssets.where((asset) => asset.isAudio).toList();

  void _selectBackgroundVideo(MediaAsset asset) {
    setState(() {
      _pendingBackgroundVideoFile = null;
      _backgroundVideoType = asset.sourceType == 'youtube' ? 'youtube' : 'video';
      _backgroundVideoCtrl.text = asset.url;
    });
    _showLoadedMessage('Video loaded from media library');
  }

  void _selectBackgroundMusic(MediaAsset asset) {
    setState(() {
      _pendingMusicFile = null;
      _backgroundMusicType = asset.sourceType == 'youtube' ? 'youtube' : 'audio';
      _musicCtrl.text = asset.url;
    });
    _showLoadedMessage('Music loaded from media library');
  }

  void _showLoadedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> _loadDetailEditAccess() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _detailEditAccessLoading = false;
          _canEditDetails = false;
          _detailEditExpiresAt = null;
        });
      }
      return false;
    }

    if (mounted) setState(() => _detailEditAccessLoading = true);
    final expiresAt = await _detailEditRequests.activePermissionExpiresAt(
      clubId: widget.club.id,
      managerId: user.id,
    );
    if (!mounted) return expiresAt != null;
    _scheduleDetailEditExpiry(expiresAt);
    setState(() {
      _detailEditExpiresAt = expiresAt;
      _canEditDetails = expiresAt != null;
      _detailEditAccessLoading = false;
    });
    return expiresAt != null;
  }

  void _scheduleDetailEditExpiry(DateTime? expiresAt) {
    _detailEditExpiryTimer?.cancel();
    if (expiresAt == null) return;

    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _lockDetailEditing();
      return;
    }

    _detailEditExpiryTimer = Timer(remaining, _lockDetailEditing);
  }

  void _lockDetailEditing() {
    if (!mounted) return;
    setState(() {
      _canEditDetails = false;
      _detailEditExpiresAt = null;
      _detailEditAccessLoading = false;
      _nameCtrl.text = widget.club.name;
      _descCtrl.text = widget.club.description;
    });
  }

  Future<void> _requestDetailEditAccess() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _requestingDetailEdit) return;

    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Request club detail edit?',
      message: 'Send a request to the university admin to temporarily unlock '
          'editing for the club name and description?',
      confirmLabel: 'Send request',
      icon: Icons.send_rounded,
    );
    if (!confirmed) return;

    setState(() => _requestingDetailEdit = true);
    try {
      final result = await _detailEditRequests.requestEditAccess(
        club: widget.club,
        manager: user,
      );
      if (!mounted) return;
      final message = switch (result) {
        ClubDetailEditRequestResult.requested =>
          'Edit request sent to university admin.',
        ClubDetailEditRequestResult.alreadyPending =>
          'Edit request reminder sent to university admin.',
        ClubDetailEditRequestResult.noAdmins =>
          'No university admin account was found.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send edit request: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _requestingDetailEdit = false);
    }
  }

  Future<void> _rememberClubMedia({
    required String videoUrl,
    required String musicUrl,
  }) async {
    try {
      await _mediaAssets.saveFromUrl(
        clubId: widget.club.id,
        name: '${widget.club.name} background video',
        url: videoUrl,
        mediaKind: 'video',
        sourceType: _backgroundVideoType,
        createdBy: widget.club.managerId,
      );
      await _mediaAssets.saveFromUrl(
        clubId: widget.club.id,
        name: '${widget.club.name} background music',
        url: musicUrl,
        mediaKind: 'audio',
        sourceType: _backgroundMusicType,
        createdBy: widget.club.managerId,
      );
      await _loadSavedMediaAssets();
    } catch (_) {
      // Media library indexing should not block updating the club profile.
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

  Future<void> _uploadBackgroundVideo() async {
    final picked = await FilePicker.pickFiles(type: FileType.video);
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _pendingBackgroundVideoFile = picked.files.single;
      _backgroundVideoType = 'video';
    });
  }

  Future<void> _uploadBackgroundMusic() async {
    final picked = await FilePicker.pickFiles(type: FileType.audio);
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _pendingMusicFile = picked.files.single;
      _backgroundMusicType = 'audio';
    });
  }

  Future<String> _uploadClubMedia(
    PlatformFile file, {
    required String loadingMessage,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loadingMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
    final result = await _cloudinary.uploadPlatformFile(file);
    return result.secureUrl;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    var backgroundVideoUrl = _backgroundVideoCtrl.text.trim();
    var backgroundMusicUrl = _musicCtrl.text.trim();
    var canSaveDetails = _canEditDetails;
    if (_canEditDetails) {
      canSaveDetails = await _loadDetailEditAccess();
      final detailsChanged = _nameCtrl.text.trim() != widget.club.name ||
          _descCtrl.text.trim() != widget.club.description;
      if (!canSaveDetails && detailsChanged) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Club details edit permission expired.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _saving = false);
        }
        return;
      }
    }

    try {
      if (_pendingBackgroundVideoFile != null) {
        backgroundVideoUrl = await _uploadClubMedia(
          _pendingBackgroundVideoFile!,
          loadingMessage: 'Uploading background video...',
        );
      }
      if (_pendingMusicFile != null) {
        backgroundMusicUrl = await _uploadClubMedia(
          _pendingMusicFile!,
          loadingMessage: 'Uploading background music...',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
      setState(() => _saving = false);
      return;
    }

    final updated = ClubModel(
      id: widget.club.id,
      name: canSaveDetails ? _nameCtrl.text.trim() : widget.club.name,
      description:
          canSaveDetails ? _descCtrl.text.trim() : widget.club.description,
      category: widget.club.category,
      logoColor: _logoColor,
      logoImageBase64: _logoImage == null ? '' : base64Encode(_logoImage!),
      showLogoBackground: _showLogoBackground,
      imageBase64: _clubImage == null ? '' : base64Encode(_clubImage!),
      galleryBase64List: _galleryImages
          .map((image) => base64Encode(image))
          .toList(growable: false),
      backgroundVideoUrl: backgroundVideoUrl,
      backgroundVideoType: _backgroundVideoType,
      backgroundVideoAutoOpen: _backgroundVideoAutoOpen,
      backgroundMusicUrl: backgroundMusicUrl,
      backgroundMusicType: _backgroundMusicType,
      backgroundMusicAutoPlay: _backgroundMusicAutoPlay,
      featureTitle: _featureTitleCtrl.text.trim(),
      featureDescription: _featureDescCtrl.text.trim(),
      featureCodeSnippet: _featureCodeCtrl.text.trim(),
      managerId: widget.club.managerId,
      managerName: widget.club.managerName,
      memberCount: widget.club.memberCount,
    );

    try {
      await ClubService().updateClub(updated);
      await _rememberClubMedia(
        videoUrl: backgroundVideoUrl,
        musicUrl: backgroundMusicUrl,
      );
      widget.onChanged?.call(updated);
      _backgroundVideoCtrl.text = backgroundVideoUrl;
      _musicCtrl.text = backgroundMusicUrl;
      _pendingBackgroundVideoFile = null;
      _pendingMusicFile = null;
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
                canEdit: _canEditDetails,
                loading: _detailEditAccessLoading,
                requesting: _requestingDetailEdit,
                permissionExpiresAt: _detailEditExpiresAt,
                onRequestEdit: _requestDetailEditAccess,
              ),

              const SizedBox(height: 18),
              _ClubExperienceCard(
                backgroundVideoCtrl: _backgroundVideoCtrl,
                backgroundVideoType: _backgroundVideoType,
                onBackgroundVideoTypeChanged: (value) =>
                    setState(() => _backgroundVideoType = value),
                backgroundVideoAutoOpen: _backgroundVideoAutoOpen,
                onBackgroundVideoAutoOpenChanged: (value) =>
                    setState(() => _backgroundVideoAutoOpen = value),
                pendingBackgroundVideoName: _pendingBackgroundVideoFile?.name,
                onUploadBackgroundVideo: _uploadBackgroundVideo,
                videoAssets: _savedVideos,
                onVideoAssetSelected: _selectBackgroundVideo,
                musicCtrl: _musicCtrl,
                musicType: _backgroundMusicType,
                onMusicTypeChanged: (value) =>
                    setState(() => _backgroundMusicType = value),
                musicAutoPlay: _backgroundMusicAutoPlay,
                onMusicAutoPlayChanged: (value) =>
                    setState(() => _backgroundMusicAutoPlay = value),
                pendingMusicName: _pendingMusicFile?.name,
                onUploadMusic: _uploadBackgroundMusic,
                audioAssets: _savedAudio,
                onAudioAssetSelected: _selectBackgroundMusic,
                featureTitleCtrl: _featureTitleCtrl,
                featureDescCtrl: _featureDescCtrl,
                featureCodeCtrl: _featureCodeCtrl,
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

