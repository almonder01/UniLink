part of '../club_profile_tab.dart';

class _ClubDetailsCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;

  const _ClubDetailsCard({
    required this.nameCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Club Details',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Club Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Club name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              minLines: 5,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'About Club',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 92),
                  child: Icon(Icons.notes_rounded),
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) => value == null || value.trim().length < 10
                  ? 'Write at least 10 characters'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
