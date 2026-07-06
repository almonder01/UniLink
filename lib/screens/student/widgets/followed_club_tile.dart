import 'package:flutter/material.dart';
import '../../../models/club.dart';
import '../../../widgets/identity_avatar.dart';

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

    return ListTile(
      onTap: onTap,
      leading: ClubAvatar(
        color: logoColor,
        logoBase64: club.logoImageBase64,
        showBackground: club.showLogoBackground,
        size: 40,
        borderRadius: 12,
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
