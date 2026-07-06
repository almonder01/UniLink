import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import 'base64_image.dart';
import 'identity_avatar.dart';

Color hexToColor(String hex) =>
    Color(int.parse('FF$hex'.substring(hex.length > 6 ? 2 : 0), radix: 16) |
        (hex.length == 8 ? 0 : 0xFF000000));

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool isLiked;
  final bool isSaved;
  final int? likeCount;
  final int? commentCount;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;

  const PostCard({
    super.key,
    required this.post,
    this.isLiked = false,
    this.isSaved = false,
    this.likeCount,
    this.commentCount,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverColor = Color(int.parse(post.coverColor, radix: 16));
    final logoColor = post.clubLogoColor != null
        ? Color(int.parse(post.clubLogoColor!, radix: 16))
        : cs.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      coverColor,
                      Color.lerp(coverColor, Colors.indigo.shade900, 0.45)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (post.coverImageBase64 != null) ...[
                      Base64Image(data: post.coverImageBase64!),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: _TypeChip(
                        icon: Icons.chat_bubble_rounded,
                        label: 'POST',
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClubAvatar(
                        color: logoColor,
                        logoBase64: post.clubLogoImageBase64,
                        showBackground: post.clubShowLogoBackground,
                        size: 30,
                        borderRadius: 9,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.clubName,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            Text(
                              DateFormat('MMM d, y').format(post.createdAt),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    post.description,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.45),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const _TagChip(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Post',
                        color: Color(0xFF14B8A6),
                      ),
                      _ActionChip(
                        icon: isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: '${likeCount ?? post.likeCount}',
                        color: isLiked ? Colors.red : null,
                        onTap: onLike,
                      ),
                      _ActionChip(
                        icon: Icons.mode_comment_outlined,
                        label: '${commentCount ?? post.commentCount}',
                        onTap: onComment,
                      ),
                      if (onSave != null)
                        _ActionChip(
                          icon: isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          label: 'Save',
                          color: isSaved ? cs.primary : null,
                          onTap: onSave,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TypeChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TagChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurface.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: effectiveColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
