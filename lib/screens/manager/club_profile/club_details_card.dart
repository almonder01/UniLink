part of '../club_profile_tab.dart';

class _ClubDetailsCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final bool canEditName;
  final bool canEditDescription;
  final bool loading;
  final DateTime? permissionExpiresAt;

  const _ClubDetailsCard({
    required this.nameCtrl,
    required this.descCtrl,
    required this.canEditName,
    required this.canEditDescription,
    required this.loading,
    required this.permissionExpiresAt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expiresAt = permissionExpiresAt;
    final canEditAny = canEditName || canEditDescription;
    final editableFields = <String>[
      if (canEditName) ClubDetailEditField.name,
      if (canEditDescription) ClubDetailEditField.description,
    ];
    final statusText = canEditAny && expiresAt != null
        ? '${ClubDetailEditField.describe(editableFields)} unlocked until '
            '${TimeOfDay.fromDateTime(expiresAt).format(context)}'
        : 'Locked. Request temporary admin permission from Club Logo.';

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(
            canEditAny ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: canEditAny ? const Color(0xFF22C55E) : cs.primary,
          ),
          title: Text(
            'Club Details',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            loading ? 'Checking edit permission...' : statusText,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.58),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              enabled: canEditName,
              decoration: const InputDecoration(
                labelText: 'Club Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: canEditName
                  ? (value) => value == null || value.trim().isEmpty
                      ? 'Club name is required'
                      : null
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              enabled: canEditDescription,
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
              validator: canEditDescription
                  ? (value) => value == null || value.trim().length < 10
                      ? 'Write at least 10 characters'
                      : null
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
