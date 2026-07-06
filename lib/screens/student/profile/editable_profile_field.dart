part of '../profile_screen.dart';

class _EditableProfileField extends StatelessWidget {
  final IconData icon;
  final bool editing;
  final TextEditingController controller;
  final String displayText;
  final String hintText;
  final Color? displayColor;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onToggle;

  const _EditableProfileField({
    required this.icon,
    required this.editing,
    required this.controller,
    required this.displayText,
    required this.hintText,
    required this.onSubmit,
    required this.onToggle,
    this.displayColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: editing
                  ? TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: hintText,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                      onSubmitted: (_) => onSubmit(),
                    )
                  : Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 14,
                        color: displayColor ?? cs.onSurface,
                      ),
                    ),
            ),
            IconButton(
              icon: Icon(
                editing ? Icons.check_rounded : Icons.edit_rounded,
                size: 18,
                color: cs.primary,
              ),
              onPressed: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
