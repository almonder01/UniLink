import 'package:flutter/material.dart';

import '../core/theme/app_theme_tokens.dart';

class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final Color? confirmColor;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.icon,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: tokens.radiusXlBorder),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor ?? cs.primary),
            SizedBox(width: tokens.spaceSm + 2),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: confirmColor == null
              ? null
              : FilledButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

Future<bool> showConfirmActionDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  IconData? icon,
  Color? confirmColor,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmActionDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      confirmColor: confirmColor,
    ),
  );
  return confirmed == true;
}
