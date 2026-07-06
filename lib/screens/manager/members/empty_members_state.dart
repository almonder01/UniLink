part of '../members_tab.dart';

class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No members yet. Tap + to add one.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
