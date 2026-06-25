import 'package:flutter/material.dart';
import '../../../models/club.dart';

class FollowedClubTile extends StatelessWidget {
  final ClubModel club;
  final VoidCallback onTap;

  const FollowedClubTile({
    super.key,
    required this.club,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logoColor = Color(int.parse(club.logoColor, radix: 16));
    final parts = club.name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : club.name.substring(0, 2).toUpperCase();

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [logoColor, Color.lerp(logoColor, Colors.black, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: Text(
        club.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        club.category,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: cs.onSurface.withValues(alpha: 0.3),
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
