import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../models/event.dart';
import '../../../widgets/base64_image.dart';

part 'event_registration/additional_requirement_section.dart';
part 'event_registration/event_registration_info.dart';
part 'event_registration/external_form_card.dart';
part 'event_registration/payment_upload_section.dart';
part 'event_registration/registration_dialog_title.dart';
part 'event_registration/registration_info_row.dart';
part 'event_registration/registration_upload_box.dart';

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
      title: const _RegistrationDialogTitle(),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventRegistrationInfo(event: event),
            if (event.hasExternalForm) ...[
              const SizedBox(height: 12),
              _ExternalFormCard(
                link: event.externalFormUrl!.trim(),
                onCopy: _copyFormLink,
              ),
            ],
            if (event.requiresPayment) ...[
              const SizedBox(height: 12),
              _PaymentUploadSection(
                event: event,
                receiptBase64: _receiptBase64,
                onPickReceipt: _pickReceipt,
              ),
            ],
            if (event.hasRegistrationRequirement) ...[
              const SizedBox(height: 12),
              _AdditionalRequirementSection(
                event: event,
                textCtrl: _requirementTextCtrl,
                fileBase64: _requirementFileBase64,
                onPickFile: _pickRequirementFile,
              ),
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
