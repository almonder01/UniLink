part of '../create_event_screen.dart';

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
