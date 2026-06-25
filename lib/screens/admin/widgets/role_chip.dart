import 'package:flutter/material.dart';

class RoleChip extends StatelessWidget {
  final String role;
  const RoleChip({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'admin':   (const Color(0xFFEF4444), const Color(0xFFfef2f2)),
      'manager': (const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      'student': (const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
    };
    final (fg, bg) = colors[role] ?? (Colors.grey, Colors.grey.shade100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
