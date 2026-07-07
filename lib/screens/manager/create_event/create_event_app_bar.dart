part of '../create_event_screen.dart';

class _CreateEventAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditing;
  final bool saving;
  final VoidCallback onSave;

  const _CreateEventAppBar({
    required this.isEditing,
    required this.saving,
    required this.onSave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(isEditing ? 'Edit Event' : 'Create Event'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isEditing
                        ? Icons.save_rounded
                        : Icons.event_available_rounded,
                    size: 18,
                  ),
            label: Text(
              saving
                  ? (isEditing ? 'Saving...' : 'Creating...')
                  : (isEditing ? 'Save' : 'Create'),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
