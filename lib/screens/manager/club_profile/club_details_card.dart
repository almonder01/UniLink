part of '../club_profile_tab.dart';

class _ClubDetailsCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final bool canEdit;
  final bool loading;
  final bool requesting;
  final DateTime? permissionExpiresAt;
  final VoidCallback onRequestEdit;

  const _ClubDetailsCard({
    required this.nameCtrl,
    required this.descCtrl,
    required this.canEdit,
    required this.loading,
    required this.requesting,
    required this.permissionExpiresAt,
    required this.onRequestEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expiresAt = permissionExpiresAt;
    final statusText = canEdit && expiresAt != null
        ? 'Unlocked until ${TimeOfDay.fromDateTime(expiresAt).format(context)}'
        : 'Locked. Request temporary admin permission to edit.';

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(
            canEdit ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: canEdit ? const Color(0xFF22C55E) : cs.primary,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Club Details',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (!canEdit)
                IconButton.filledTonal(
                  tooltip: 'Request edit permission',
                  onPressed: loading || requesting ? null : onRequestEdit,
                  icon: requesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
            ],
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
              enabled: canEdit,
              decoration: const InputDecoration(
                labelText: 'Club Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: canEdit
                  ? (value) => value == null || value.trim().isEmpty
                      ? 'Club name is required'
                      : null
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              enabled: canEdit,
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
              validator: canEdit
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
