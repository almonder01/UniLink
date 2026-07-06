import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../models/event.dart';
import '../../../widgets/base64_image.dart';

class EventRegistrationSubmission {
  final String? paymentReceiptBase64;
  final String? requirementTextResponse;
  final String? requirementFileBase64;

  const EventRegistrationSubmission({
    this.paymentReceiptBase64,
    this.requirementTextResponse,
    this.requirementFileBase64,
  });
}

Future<EventRegistrationSubmission?> showEventRegistrationDialog(
  BuildContext context, {
  required EventModel event,
}) async {
  return showDialog<EventRegistrationSubmission?>(
    context: context,
    builder: (_) => _EventRegistrationDialog(event: event),
  );
}

class _EventRegistrationDialog extends StatefulWidget {
  final EventModel event;

  const _EventRegistrationDialog({required this.event});

  @override
  State<_EventRegistrationDialog> createState() =>
      _EventRegistrationDialogState();
}

class _EventRegistrationDialogState extends State<_EventRegistrationDialog> {
  final _picker = ImagePicker();
  final _requirementTextCtrl = TextEditingController();
  String? _receiptBase64;
  String? _requirementFileBase64;

  @override
  void dispose() {
    _requirementTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 72,
    );
    if (file == null) return;
    final encoded = base64Encode(await file.readAsBytes());
    if (mounted) setState(() => _receiptBase64 = encoded);
  }

  Future<void> _pickRequirementFile() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 72,
    );
    if (file == null) return;
    final encoded = base64Encode(await file.readAsBytes());
    if (mounted) setState(() => _requirementFileBase64 = encoded);
  }

  Future<void> _copyFormLink() async {
    final link = widget.event.externalFormUrl?.trim();
    if (link == null || link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form link copied.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirm() {
    final event = widget.event;
    if (event.requiresPayment && (_receiptBase64 ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the transfer receipt first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (event.requiresRegistrationText &&
        _requirementTextCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill the additional requirement.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (event.requiresRegistrationFile &&
        (_requirementFileBase64 ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the required file.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      EventRegistrationSubmission(
        paymentReceiptBase64: _receiptBase64,
        requirementTextResponse: _requirementTextCtrl.text.trim().isEmpty
            ? null
            : _requirementTextCtrl.text.trim(),
        requirementFileBase64: _requirementFileBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final event = widget.event;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: Color(0xFFF97316),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Registration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: DateFormat('EEE, MMM d, y').format(event.eventDate),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: DateFormat('h:mm a').format(event.eventDate),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: event.location,
          ),
          if (event.hasCapacityLimit) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.groups_rounded,
              label:
                  '${event.registeredCount}/${event.maxParticipants} registered',
            ),
          ],
          if (event.hasExternalForm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'External form',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.externalFormUrl!.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _copyFormLink,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy link'),
                  ),
                ],
              ),
            ),
          ],
          if (event.requiresPayment) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded,
                      color: Color(0xFF14B8A6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment required: ${event.feeLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickReceipt,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 92,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (_receiptBase64 ?? '').isEmpty
                        ? cs.onSurface.withValues(alpha: 0.12)
                        : cs.primary.withValues(alpha: 0.55),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: (_receiptBase64 ?? '').isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_rounded,
                              color: cs.primary, size: 24),
                          const SizedBox(height: 5),
                          const Text(
                            'Upload transfer receipt',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    : TappableBase64Image(data: _receiptBase64!),
              ),
            ),
          ],
          if (event.hasRegistrationRequirement) ...[
            const SizedBox(height: 12),
            Text(
              event.registrationRequirementPrompt?.trim().isNotEmpty == true
                  ? event.registrationRequirementPrompt!.trim()
                  : 'Additional registration requirement',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (event.requiresRegistrationText) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _requirementTextCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Your answer',
                  alignLabelWithHint: true,
                ),
              ),
            ],
            if (event.requiresRegistrationFile) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickRequirementFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 92,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_requirementFileBase64 ?? '').isEmpty
                          ? cs.onSurface.withValues(alpha: 0.12)
                          : cs.primary.withValues(alpha: 0.55),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (_requirementFileBase64 ?? '').isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_file_rounded,
                                color: cs.primary, size: 24),
                            const SizedBox(height: 5),
                            const Text(
                              'Upload required file',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : TappableBase64Image(data: _requirementFileBase64!),
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Text(
            event.requiresPayment
                ? 'Your registration will be pending until the club manager approves the receipt.'
                : 'Do you want to register for this event?',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.62),
            ),
          ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.onSurface.withValues(alpha: 0.48)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}
