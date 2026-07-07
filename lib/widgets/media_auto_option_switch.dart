import 'package:flutter/material.dart';

class MediaAutoOptionSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;

  const MediaAutoOptionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.58),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
