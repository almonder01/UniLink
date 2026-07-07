import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../models/club.dart';
import '../../models/event.dart';
import '../../models/media_asset.dart';
import '../../services/cloudinary_upload_service.dart';
import '../../services/event_service.dart';
import '../../services/media_asset_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/media_attachment_fields.dart';
import '../../widgets/youtube_video_preview.dart';
import 'additional_photos_grid.dart';
import 'color_swatch_picker.dart';
import 'cover_photo_picker.dart';
import 'event_datetime_card.dart';
import 'event_location_picker_screen.dart';

part 'create_event/event_fee_card.dart';
part 'create_event/registration_options_card.dart';
part 'create_event/create_event_app_bar.dart';
part 'create_event/event_basic_info_section.dart';

class CreateEventScreen extends StatefulWidget {
  final ClubModel club;
  final EventModel? existingEvent;

  const CreateEventScreen({
    super.key,
    required this.club,
    this.existingEvent,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _externalFormCtrl = TextEditingController();
  final _requirementPromptCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _audioUrlCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryUploadService();
  final _mediaAssets = MediaAssetService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? _selectedMapLocation;
  bool _saving = false;
  PlatformFile? _pendingVideoFile;
  PlatformFile? _pendingAudioFile;
  String _videoType = 'youtube';
  String _audioType = 'audio';
  String _selectedColor = 'FFFF6B35';
  String _feeCurrency = 'RM';
  bool _requiresRegistrationText = false;
  bool _requiresRegistrationFile = false;
  Uint8List? _coverImage;
  final List<Uint8List> _additionalImages = [];
  List<MediaAsset> _savedMediaAssets = [];

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    _youtubeCtrl.addListener(() => setState(() {}));
    _videoUrlCtrl.addListener(() => setState(() {}));
    _audioUrlCtrl.addListener(() => setState(() {}));
    _loadSavedMediaAssets();
    final event = widget.existingEvent;
    if (event == null) return;

    _titleCtrl.text = event.title;
    _descCtrl.text = event.description;
    _locationCtrl.text = event.location;
    _selectedColor = event.coverColor;
    _selectedDate = event.eventDate;
    _selectedTime = TimeOfDay.fromDateTime(event.eventDate);
    _feeCtrl.text =
        event.feeAmount == null ? '' : event.feeAmount!.toStringAsFixed(2);
    _feeCurrency = event.feeCurrency;
    _capacityCtrl.text =
        event.maxParticipants == null ? '' : '${event.maxParticipants}';
    _externalFormCtrl.text = event.externalFormUrl ?? '';
    _requirementPromptCtrl.text = event.registrationRequirementPrompt ?? '';
    _youtubeCtrl.text = event.youtubeUrl ?? '';
    _videoUrlCtrl.text = event.videoUrl ?? '';
    _audioUrlCtrl.text = event.audioUrl ?? '';
    _videoType = (event.videoUrl ?? '').trim().isNotEmpty ? 'video' : 'youtube';
    _audioType = event.audioType == 'youtube' ? 'youtube' : 'audio';
    _requiresRegistrationText = event.requiresRegistrationText;
    _requiresRegistrationFile = event.requiresRegistrationFile;
    if (event.latitude != null && event.longitude != null) {
      _selectedMapLocation = LatLng(event.latitude!, event.longitude!);
    }
    _coverImage = _decodeImage(event.coverImageBase64);
    _additionalImages.addAll(
      event.photoBase64List
          .map(_decodeImage)
          .whereType<Uint8List>()
          .take(5),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _feeCtrl.dispose();
    _capacityCtrl.dispose();
    _externalFormCtrl.dispose();
    _requirementPromptCtrl.dispose();
    _youtubeCtrl.dispose();
    _videoUrlCtrl.dispose();
    _audioUrlCtrl.dispose();
    super.dispose();
  }

  bool _isValidOptionalUrl(String url) {
    if (url.isEmpty) return true;
    return youtubeVideoIdFromUrl(url) != null;
  }

  bool _isValidOptionalHttpUrl(String url) {
    if (url.isEmpty) return true;
    return url.startsWith('http://') || url.startsWith('https://');
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
      // Media library indexing should not block saving the event.
    }
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

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = _selectedDate == null
        ? null
        : DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );
    final firstDate = _isEditing &&
            selectedDateOnly != null &&
            selectedDateOnly.isBefore(todayOnly)
        ? selectedDateOnly
        : todayOnly;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: todayOnly.add(const Duration(days: 365)),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickMapLocation() async {
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => EventLocationPickerScreen(
          initialLocation: _selectedMapLocation,
        ),
      ),
    );
    if (picked != null) setState(() => _selectedMapLocation = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    setState(() => _saving = true);
    final eventDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime?.hour ?? 10,
      _selectedTime?.minute ?? 0,
    );
    final coverImageBase64 =
        _coverImage == null ? null : base64Encode(_coverImage!);
    final photoBase64List =
        _additionalImages.map((bytes) => base64Encode(bytes)).toList();
    final rawFee = _feeCtrl.text.trim();
    final feeAmount = rawFee.isEmpty ? null : double.tryParse(rawFee);
    if (rawFee.isNotEmpty && (feeAmount == null || feeAmount <= 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid event fee or leave it empty.'),
          ),
        );
      }
      setState(() => _saving = false);
      return;
    }
    final rawCapacity = _capacityCtrl.text.trim();
    final maxParticipants =
        rawCapacity.isEmpty ? null : int.tryParse(rawCapacity);
    if (rawCapacity.isNotEmpty &&
        (maxParticipants == null || maxParticipants <= 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid participant limit or leave it empty.'),
          ),
        );
      }
      setState(() => _saving = false);
      return;
    }
    if (maxParticipants != null &&
        widget.existingEvent != null &&
        maxParticipants < widget.existingEvent!.registeredCount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Limit cannot be below current registrations (${widget.existingEvent!.registeredCount}).',
            ),
          ),
        );
      }
      setState(() => _saving = false);
      return;
    }
    final externalFormUrl = _externalFormCtrl.text.trim();
    if (externalFormUrl.isNotEmpty &&
        !(externalFormUrl.startsWith('http://') ||
            externalFormUrl.startsWith('https://'))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('External form link must start with http:// or https://.'),
          ),
        );
      }
      setState(() => _saving = false);
      return;
    }
    final requirementPrompt = _requirementPromptCtrl.text.trim();
    final youtubeUrl = _videoType == 'youtube' ? _youtubeCtrl.text.trim() : '';
    var videoUrl = _videoType == 'video' ? _videoUrlCtrl.text.trim() : '';
    var audioUrl = _audioUrlCtrl.text.trim();
    if (_videoType == 'youtube' && !_isValidOptionalUrl(youtubeUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video link must be a valid YouTube link.'),
          ),
        );
      }
      setState(() => _saving = false);
      return;
    }
    if (_videoType == 'video' &&
        _pendingVideoFile == null &&
        !_isValidOptionalHttpUrl(videoUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video link must start with http:// or https://.')),
        );
      }
      setState(() => _saving = false);
      return;
    }

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
      final existing = widget.existingEvent;
      final event = EventModel(
        id: existing?.id ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        latitude: _selectedMapLocation?.latitude,
        longitude: _selectedMapLocation?.longitude,
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
        eventDate: eventDate,
        feeAmount: feeAmount,
        feeCurrency: _feeCurrency,
        maxParticipants: maxParticipants,
        externalFormUrl: externalFormUrl.isEmpty ? null : externalFormUrl,
        registrationRequirementPrompt:
            requirementPrompt.isEmpty ? null : requirementPrompt,
        requiresRegistrationText: _requiresRegistrationText,
        requiresRegistrationFile: _requiresRegistrationFile,
        registeredCount: existing?.registeredCount ?? 0,
        attendedCount: existing?.attendedCount ?? 0,
      );

      if (_isEditing) {
        await EventService().updateEvent(event);
      } else {
        await EventService().saveEvent(event);
        NotificationService()
            .notifyFollowers(
              clubId: widget.club.id,
              title: 'New event from ${widget.club.name}',
              body: event.title,
              type: 'event',
              color: widget.club.logoColor,
              refId: event.id,
            )
            .catchError((_) {});
      }
      await _rememberMedia(
        title: event.title,
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
                ? 'Event updated successfully!'
                : 'Event created successfully!'),
          ]),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, event);
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
    final previewColor = Color(int.parse(_selectedColor, radix: 16));

    return Scaffold(
      appBar: _CreateEventAppBar(
        isEditing: _isEditing,
        saving: _saving,
        onSave: _save,
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
              ),
              const SizedBox(height: 20),
              _EventBasicInfoSection(
                titleCtrl: _titleCtrl,
                descCtrl: _descCtrl,
              ),
              const SizedBox(height: 16),
              EventDateTimeCard(
                locationCtrl: _locationCtrl,
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                selectedMapLocation: _selectedMapLocation,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
                onPickMap: _pickMapLocation,
              ),
              const SizedBox(height: 16),
              _EventFeeCard(
                feeCtrl: _feeCtrl,
                currency: _feeCurrency,
                onCurrencyChanged: (value) {
                  if (value == null) return;
                  setState(() => _feeCurrency = value);
                },
              ),
              const SizedBox(height: 16),
              _RegistrationOptionsCard(
                capacityCtrl: _capacityCtrl,
                externalFormCtrl: _externalFormCtrl,
                requirementPromptCtrl: _requirementPromptCtrl,
                requiresText: _requiresRegistrationText,
                requiresFile: _requiresRegistrationFile,
                onRequiresTextChanged: (value) {
                  setState(() => _requiresRegistrationText = value);
                },
                onRequiresFileChanged: (value) {
                  setState(() => _requiresRegistrationFile = value);
                },
              ),
              const SizedBox(height: 16),
              MediaAttachmentFields(
                title: 'Media',
                subtitle: 'Add one video source and optional event music.',
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
                videoPreviewTitle: 'Event video preview',
                audioPreviewTitle: 'Event music preview',
              ),
              const SizedBox(height: 16),
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
