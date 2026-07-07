import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../models/media_asset.dart';
import '../../services/cloudinary_upload_service.dart';
import '../../services/media_asset_service.dart';
import '../../widgets/media_attachment_fields.dart';
import '../../widgets/youtube_video_preview.dart';
import 'media_asset_name_dialog.dart';

part 'media_library/library_section.dart';

class MediaLibraryScreen extends StatefulWidget {
  final ClubModel club;

  const MediaLibraryScreen({
    super.key,
    required this.club,
  });

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  final _youtubeVideoCtrl = TextEditingController();
  final _directVideoCtrl = TextEditingController();
  final _audioCtrl = TextEditingController();
  final _videoNameCtrl = TextEditingController();
  final _audioNameCtrl = TextEditingController();
  final _mediaAssets = MediaAssetService();
  final _cloudinary = CloudinaryUploadService();

  String _videoType = 'youtube';
  String _audioType = 'audio';
  PlatformFile? _pendingVideoFile;
  PlatformFile? _pendingAudioFile;
  List<MediaAsset> _assets = [];
  bool _loading = true;
  bool _savingVideo = false;
  bool _savingAudio = false;

  @override
  void initState() {
    super.initState();
    _youtubeVideoCtrl.addListener(() => setState(() {}));
    _directVideoCtrl.addListener(() => setState(() {}));
    _audioCtrl.addListener(() => setState(() {}));
    _loadAssets();
  }

  @override
  void dispose() {
    _youtubeVideoCtrl.dispose();
    _directVideoCtrl.dispose();
    _audioCtrl.dispose();
    _videoNameCtrl.dispose();
    _audioNameCtrl.dispose();
    super.dispose();
  }

  List<MediaAsset> get _videos =>
      _assets.where((asset) => asset.isVideo).toList();

  List<MediaAsset> get _audio =>
      _assets.where((asset) => asset.isAudio).toList();

  Future<void> _loadAssets() async {
    final assets = await _mediaAssets.getAssetsForClub(widget.club.id);
    if (mounted) {
      setState(() {
        _assets = assets;
        _loading = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await FilePicker.pickFiles(type: FileType.video);
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _pendingVideoFile = picked.files.single;
      _videoType = 'video';
    });
  }

  Future<void> _pickAudio() async {
    final picked = await FilePicker.pickFiles(type: FileType.audio);
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _pendingAudioFile = picked.files.single;
      _audioType = 'audio';
    });
  }

  void _selectVideoAsset(MediaAsset asset) {
    setState(() {
      _pendingVideoFile = null;
      _videoNameCtrl.text = asset.name;
      if (asset.sourceType == 'youtube') {
        _videoType = 'youtube';
        _youtubeVideoCtrl.text = asset.url;
        _directVideoCtrl.clear();
      } else {
        _videoType = 'video';
        _directVideoCtrl.text = asset.url;
        _youtubeVideoCtrl.clear();
      }
    });
    _showSnack('Video loaded from library');
  }

  void _selectAudioAsset(MediaAsset asset) {
    setState(() {
      _pendingAudioFile = null;
      _audioNameCtrl.text = asset.name;
      _audioType = asset.sourceType == 'youtube' ? 'youtube' : 'audio';
      _audioCtrl.text = asset.url;
    });
    _showSnack('Music loaded from library');
  }

  Future<void> _saveVideo() async {
    if (_savingVideo) return;
    setState(() => _savingVideo = true);
    try {
      var url = _videoType == 'youtube'
          ? _youtubeVideoCtrl.text.trim()
          : _directVideoCtrl.text.trim();
      if (_pendingVideoFile != null && _videoType == 'video') {
        _showSnack('Uploading video...');
        final upload = await _cloudinary.uploadPlatformFile(_pendingVideoFile!);
        url = upload.secureUrl;
      }
      if (!_isValidVideoUrl(url)) {
        _showSnack('Enter a valid video link or choose a video file.');
        return;
      }
      await _mediaAssets.saveFromUrl(
        clubId: widget.club.id,
        name: _videoNameCtrl.text.trim().isEmpty
            ? '${widget.club.name} video'
            : _videoNameCtrl.text.trim(),
        url: url,
        mediaKind: 'video',
        sourceType: _videoType,
        createdBy: widget.club.managerId,
      );
      _directVideoCtrl.text = _videoType == 'video' ? url : '';
      _pendingVideoFile = null;
      await _loadAssets();
      _showSnack('Video saved to media library');
    } catch (e) {
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _savingVideo = false);
    }
  }

  Future<void> _saveAudio() async {
    if (_savingAudio) return;
    setState(() => _savingAudio = true);
    try {
      var url = _audioCtrl.text.trim();
      if (_pendingAudioFile != null && _audioType == 'audio') {
        _showSnack('Uploading audio...');
        final upload = await _cloudinary.uploadPlatformFile(_pendingAudioFile!);
        url = upload.secureUrl;
      }
      if (!_isValidAudioUrl(url)) {
        _showSnack('Enter a valid audio link or choose an audio file.');
        return;
      }
      await _mediaAssets.saveFromUrl(
        clubId: widget.club.id,
        name: _audioNameCtrl.text.trim().isEmpty
            ? '${widget.club.name} music'
            : _audioNameCtrl.text.trim(),
        url: url,
        mediaKind: 'audio',
        sourceType: _audioType,
        createdBy: widget.club.managerId,
      );
      _audioCtrl.text = url;
      _pendingAudioFile = null;
      await _loadAssets();
      _showSnack('Music saved to media library');
    } catch (e) {
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _savingAudio = false);
    }
  }

  Future<void> _renameAsset(MediaAsset asset) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => MediaAssetNameDialog(initialName: asset.name),
    );
    if (name == null || name.trim().isEmpty) return;
    await _mediaAssets.updateName(assetId: asset.id, name: name);
    await _loadAssets();
    _showSnack('Media renamed');
  }

  bool _isValidVideoUrl(String url) {
    if (url.isEmpty) return false;
    if (_videoType == 'youtube') return youtubeVideoIdFromUrl(url) != null;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool _isValidAudioUrl(String url) {
    if (url.isEmpty) return false;
    if (_audioType == 'youtube') return youtubeVideoIdFromUrl(url) != null;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Library'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssets,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            MediaAttachmentFields(
              title: 'Add or reuse media',
              subtitle: 'Save links once, then use them in posts and events.',
              youtubeVideoController: _youtubeVideoCtrl,
              directVideoController: _directVideoCtrl,
              videoType: _videoType,
              onVideoTypeChanged: (value) => setState(() => _videoType = value),
              onPickVideo: _pickVideo,
              pendingVideoName: _pendingVideoFile?.name,
              videoAssets: _videos,
              selectedVideoUrl: _videoType == 'youtube'
                  ? _youtubeVideoCtrl.text.trim()
                  : _directVideoCtrl.text.trim(),
              onVideoAssetSelected: _selectVideoAsset,
              audioController: _audioCtrl,
              audioType: _audioType,
              onAudioTypeChanged: (value) => setState(() => _audioType = value),
              onPickAudio: _pickAudio,
              pendingAudioName: _pendingAudioFile?.name,
              audioAssets: _audio,
              selectedAudioUrl: _audioCtrl.text.trim(),
              onAudioAssetSelected: _selectAudioAsset,
              videoPreviewTitle: 'Video preview',
              audioPreviewTitle: 'Music preview',
              videoOptions: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _videoNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Video display name',
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _savingVideo ? null : _saveVideo,
                    icon: _savingVideo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Save video'),
                  ),
                ),
              ],
              audioOptions: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _audioNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Music display name',
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _savingAudio ? null : _saveAudio,
                    icon: _savingAudio
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Save music'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _LibrarySection(
              title: 'Videos',
              emptyText: 'No saved videos yet.',
              assets: _videos,
              onRename: _renameAsset,
            ),
            const SizedBox(height: 14),
            _LibrarySection(
              title: 'Music',
              emptyText: 'No saved music yet.',
              assets: _audio,
              onRename: _renameAsset,
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: CircularProgressIndicator(color: cs.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
