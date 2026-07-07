part of '../event_dashboard_tab.dart';

class _EventDocumentsPanel extends StatelessWidget {
  final EventModel event;

  const _EventDocumentsPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<EventRegistration>>(
      future: EventService().getRegistrationsForEvent(event.id),
      builder: (context, snapshot) {
        final registrations = snapshot.data ?? const <EventRegistration>[];
        final files = registrations
            .where((registration) =>
                (registration.requirementFileBase64 ?? '').isNotEmpty)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link_rounded),
              title: const Text('External form'),
              subtitle: Text(event.externalFormUrl?.isNotEmpty == true
                  ? event.externalFormUrl!
                  : 'No external form link'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rule_folder_rounded),
              title: const Text('Additional requirement'),
              subtitle: Text(
                event.registrationRequirementPrompt?.isNotEmpty == true
                    ? event.registrationRequirementPrompt!
                    : 'No additional requirement prompt',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${files.length} uploaded requirement file(s)',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...files.take(5).map(
                  (registration) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file_rounded),
                    title: Text(registration.userName),
                    subtitle: Text(registration.userEmail),
                    trailing: TextButton(
                      onPressed: () => showBase64ImagePreview(
                        context,
                        data: registration.requirementFileBase64!,
                      ),
                      child: const Text('View'),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
