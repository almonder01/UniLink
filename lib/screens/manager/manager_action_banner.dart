import 'package:flutter/material.dart';

class ManagerActionBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tooltip;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;

  const ManagerActionBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tooltip,
    required this.onPressed,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(subtitle),
          trailing: IconButton.filledTonal(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ),
    );
  }
}
