import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../services/notification_service.dart';
import 'additional_photos_grid.dart';
import 'color_swatch_picker.dart';
import 'cover_photo_picker.dart';
import 'event_datetime_card.dart';

class CreateEventScreen extends StatefulWidget {
  final ClubModel club;

  /// Pass an existing event to enter edit mode.
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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;
  String _selectedColor = 'FFFF6B35';
  Uint8List? _coverImage;
  final List<Uint8List> _additionalImages = [];
  final _picker = ImagePicker();

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    if (_isEditing) {
      final e = widget.existingEvent!;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _locationCtrl.text = e.location;
      _selectedColor = e.coverColor;
      _selectedDate = e.eventDate;
      _selectedTime = TimeOfDay.fromDateTime(e.eventDate);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _coverImage = bytes);
  }

  Future<void> _pickAdditional() async {
    if (_additionalImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 additional photos')));
      return;
    }
    final file = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _additionalImages.add(bytes));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    try {
      if (_isEditing) {
        // ── Update existing event ─────────────────────────────────────────
        final updated = EventModel(
          id: widget.existingEvent!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          clubId: widget.existingEvent!.clubId,
          clubName: widget.existingEvent!.clubName,
          clubLogoColor: widget.existingEvent!.clubLogoColor,
          coverColor: _selectedColor,
          eventDate: eventDate,
        );

        await FirebaseFirestore.instance
            .collection('events')
            .doc(updated.id)
            .update(updated.toMap());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Event updated successfully!'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, updated);
      } else {
        // ── Create new event ──────────────────────────────────────────────
        final newEvent = EventModel(
          id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          clubId: widget.club.id,
          clubName: widget.club.name,
          clubLogoColor: widget.club.logoColor,
          coverColor: _selectedColor,
          eventDate: eventDate,
        );

        await FirebaseFirestore.instance
            .collection('events')
            .doc(newEvent.id)
            .set(newEvent.toMap());

        NotificationService()
            .notifyFollowers(
              clubId: widget.club.id,
              title: 'New event from ${widget.club.name}',
              body: newEvent.title,
              type: 'event',
              color: widget.club.logoColor,
              refId: newEvent.id,
            )
            .catchError((_) {});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Event created successfully!'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, newEvent);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      _isEditing
                          ? Icons.save_rounded
                          : Icons.event_available_rounded,
                      size: 18),
              label: Text(_saving
                  ? (_isEditing ? 'Saving...' : 'Creating...')
                  : (_isEditing ? 'Save' : 'Create')),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: null,
                minLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, height: 1.65),
                decoration: const InputDecoration(
                  hintText: 'Describe this event...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
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
                onPickDate: _pickDate,
                onPickTime: _pickTime,
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