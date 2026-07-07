part of '../media_attachment_fields.dart';

class _MediaSourceSelector extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final List<ButtonSegment<String>> segments;
  final ValueChanged<String> onChanged;

  const _MediaSourceSelector({
    required this.title,
    required this.icon,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: segments,
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ],
    );
  }
}
