import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../services/notification_service.dart';

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

  static const _swatches = [
    'FFFF6B35',
    'FFF97316',
    'FFEF4444',
    'FFEC4899',
    'FFA855F7',
    'FF6366F1',
    'FF3B82F6',
    'FF14B8A6',
    'FF10B981',
    'FF22C55E',
  ];

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
              // Cover photo
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: previewColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _coverImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_coverImage!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Change',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                previewColor,
                                Color.lerp(
                                    previewColor, Colors.orange.shade900, 0.4)!
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  size: 44,
                                  color: Colors.white.withValues(alpha: 0.85)),
                              const SizedBox(height: 8),
                              Text('Tap to add cover photo',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Optional',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Color picker
              Text('Event Accent Color',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _swatches.map((hex) {
                  final c = Color(int.parse(hex, radix: 16));
                  final selected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? cs.onSurface : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
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
              Divider(color: cs.onSurface.withValues(alpha: 0.1)),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on_rounded),
                          hintText: 'e.g. Block B, Auditorium',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a location'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Date picker
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 20,
                                  color: _selectedDate != null
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.45)),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate != null
                                    ? DateFormat('EEEE, MMMM d, y')
                                        .format(_selectedDate!)
                                    : 'Select Date',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedDate != null
                                        ? cs.onSurface
                                        : cs.onSurface.withValues(alpha: 0.45),
                                    fontWeight: _selectedDate != null
                                        ? FontWeight.w500
                                        : FontWeight.w400),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right_rounded,
                                  color: cs.onSurface.withValues(alpha: 0.3)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Time picker
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 20,
                                  color: _selectedTime != null
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.45)),
                              const SizedBox(width: 12),
                              Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select Time',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedTime != null
                                        ? cs.onSurface
                                        : cs.onSurface.withValues(alpha: 0.45),
                                    fontWeight: _selectedTime != null
                                        ? FontWeight.w500
                                        : FontWeight.w400),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right_rounded,
                                  color: cs.onSurface.withValues(alpha: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Additional photos
              Row(
                children: [
                  Text('Additional Photos',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(width: 8),
                  Text('${_additionalImages.length}/5',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._additionalImages.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(entry.value,
                                  width: 90, height: 90, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _additionalImages.removeAt(entry.key)),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_additionalImages.length < 5)
                      GestureDetector(
                        onTap: _pickAdditional,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: cs.onSurface.withValues(alpha: 0.15),
                                width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                  size: 28),
                              const SizedBox(height: 4),
                              Text('Add',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
