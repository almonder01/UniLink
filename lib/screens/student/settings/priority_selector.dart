part of '../settings_screen.dart';

class _PrioritySelector extends StatelessWidget {
  final String title;
  final String value;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'member_first',
                label: Text('Member'),
                icon: Icon(Icons.groups_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'followed_first',
                label: Text('Followed'),
                icon: Icon(Icons.notifications_active_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'recent',
                label: Text('Recent'),
                icon: Icon(Icons.schedule_rounded, size: 16),
              ),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
