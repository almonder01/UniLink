import 'package:flutter/material.dart';
import '../core/theme/app_theme_tokens.dart';
import '../models/club.dart';
import 'identity_avatar.dart';

class ClubCard extends StatelessWidget {
  final ClubModel club;
  final bool isFollowed;
  final VoidCallback? onTap;
  final VoidCallback? onFollowToggle;

  const ClubCard({
    super.key,
    required this.club,
    required this.isFollowed,
    this.onTap,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final logoColor = Color(int.parse(club.logoColor, radix: 16));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: tokens.radiusXlBorder,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radiusLg + 2),
                  boxShadow: [
                    BoxShadow(
                      color: logoColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClubAvatar(
                  color: logoColor,
                  logoBase64: club.logoImageBase64,
                  showBackground: club.showLogoBackground,
                  size: 64,
                  borderRadius: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                club.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: logoColor.withValues(alpha: 0.1),
                  borderRadius: tokens.radiusPillBorder,
                ),
                child: Text(
                  club.category,
                  style: TextStyle(
                      fontSize: 10,
                      color: logoColor,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_rounded,
                      size: 12, color: cs.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${club.memberCount} members',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: isFollowed
                    ? OutlinedButton(
                        onPressed: onFollowToggle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 14),
                              SizedBox(width: 4),
                              Text('Following'),
                            ],
                          ),
                        ),
                      )
                    : FilledButton(
                        onPressed: onFollowToggle,
                        style: FilledButton.styleFrom(
                          backgroundColor: logoColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Follow'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
