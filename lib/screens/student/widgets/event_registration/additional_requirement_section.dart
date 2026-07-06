part of '../event_registration_dialog.dart';

class _AdditionalRequirementSection extends StatelessWidget {
  final EventModel event;
  final TextEditingController textCtrl;
  final String? fileBase64;
  final VoidCallback onPickFile;

  const _AdditionalRequirementSection({
    required this.event,
    required this.textCtrl,
    required this.fileBase64,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.registrationRequirementPrompt?.trim().isNotEmpty == true
              ? event.registrationRequirementPrompt!.trim()
              : 'Additional registration requirement',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        if (event.requiresRegistrationText) ...[
          const SizedBox(height: 8),
          TextField(
            controller: textCtrl,
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
          _RegistrationUploadBox(
            data: fileBase64,
            icon: Icons.attach_file_rounded,
            label: 'Upload required file',
            onTap: onPickFile,
          ),
        ],
      ],
    );
  }
}
