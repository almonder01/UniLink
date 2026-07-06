import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../models/club.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/notification_service.dart';
import 'additional_photos_grid.dart';
import 'color_swatch_picker.dart';
import 'cover_photo_picker.dart';
import 'event_datetime_card.dart';
import 'event_location_picker_screen.dart';

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
  final _picker = ImagePicker();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? _selectedMapLocation;
  bool _saving = false;
  String _selectedColor = 'FFFF6B35';
  String _feeCurrency = 'RM';
  bool _requiresRegistrationText = false;
  bool _requiresRegistrationFile = false;
  Uint8List? _coverImage;
  final List<Uint8List> _additionalImages = [];

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
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

    try {
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
    final cs = Theme.of(context).colorScheme;
    final previewColor = Color(int.parse(_selectedColor, radix: 16));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
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
                      _isEditing
                          ? Icons.save_rounded
                          : Icons.event_available_rounded,
                      size: 18,
                    ),
              label: Text(
                _saving
                    ? (_isEditing ? 'Saving...' : 'Creating...')
                    : (_isEditing ? 'Save' : 'Create'),
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
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: 'Event title...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.1),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: null,
                minLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, height: 1.65),
                decoration: InputDecoration(
                  hintText: 'Describe this event...',
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
                    ? 'Please add a description (min 10 chars)'
                    : null,
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

class _EventFeeCard extends StatelessWidget {
  final TextEditingController feeCtrl;
  final String currency;
  final ValueChanged<String?> onCurrencyChanged;

  const _EventFeeCard({
    required this.feeCtrl,
    required this.currency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: Color(0xFF14B8A6), size: 19),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Event Payment',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: const [
                      DropdownMenuItem(value: 'RM', child: Text('RM')),
                      DropdownMenuItem(value: 'USD', child: Text(r'$')),
                    ],
                    onChanged: onCurrencyChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: feeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: 'Leave empty if free',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'If an amount is set, students must upload a transfer receipt before registering.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationOptionsCard extends StatelessWidget {
  final TextEditingController capacityCtrl;
  final TextEditingController externalFormCtrl;
  final TextEditingController requirementPromptCtrl;
  final bool requiresText;
  final bool requiresFile;
  final ValueChanged<bool> onRequiresTextChanged;
  final ValueChanged<bool> onRequiresFileChanged;

  const _RegistrationOptionsCard({
    required this.capacityCtrl,
    required this.externalFormCtrl,
    required this.requirementPromptCtrl,
    required this.requiresText,
    required this.requiresFile,
    required this.onRequiresTextChanged,
    required this.onRequiresFileChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fact_check_rounded,
                      color: cs.primary, size: 19),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Registration Settings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max participants',
                hintText: 'Leave empty for unlimited',
                prefixIcon: Icon(Icons.groups_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: externalFormCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'External form link',
                hintText: 'Optional Google Form link',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: requirementPromptCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional requirement',
                hintText:
                    'Optional: Tell students what answer or file you need, e.g. upload transfer receipt or write your team name.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: requiresText,
              onChanged: onRequiresTextChanged,
              title: const Text(
                'Require written answer',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              secondary: const Icon(Icons.notes_rounded),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: requiresFile,
              onChanged: onRequiresFileChanged,
              title: const Text(
                'Require uploaded file',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              secondary: const Icon(Icons.upload_file_rounded),
            ),
            Text(
              'If any requirement is enabled, registrations stay pending until the manager approves them.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
