import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme_tokens.dart';
import '../models/post.dart';
import 'app_surface.dart';
import 'base64_image.dart';
import 'identity_avatar.dart';

part 'post_card/type_chip.dart';
part 'post_card/tag_chip.dart';
part 'post_card/action_chip.dart';

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
  final VoidCallback? onShare;
  final VoidCallback? onClubTap;

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
    this.onShare,
    this.onClubTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final coverColor = Color(int.parse(post.coverColor, radix: 16));
    final logoColor = post.clubLogoColor != null
        ? Color(int.parse(post.clubLogoColor!, radix: 16))
        : cs.primary;

    return AppSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 6,
            child: Container(
              decoration: BoxDecoration(
                gradient: tokens.postGradient(coverColor),
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
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _TypeChip(
                      icon: Icons.chat_bubble_rounded,
                      label: 'POST',
                      color: tokens.info,
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
                InkWell(
                  onTap: onClubTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
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
                    _TagChip(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Post',
                      color: tokens.info,
                    ),
                    if ((post.youtubeUrl ?? '').trim().isNotEmpty ||
                        (post.videoUrl ?? '').trim().isNotEmpty)
                      const _TagChip(
                        icon: Icons.smart_display_rounded,
                        label: 'Video',
                        color: Color(0xFFFF0000),
                      ),
                    if ((post.audioUrl ?? '').trim().isNotEmpty)
                      _TagChip(
                        icon: Icons.music_note_rounded,
                        label: 'Music',
                        color: tokens.accent,
                      ),
                    _ActionChip(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '${likeCount ?? post.likeCount}',
                      color: isLiked ? tokens.danger : null,
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
                    if (onShare != null)
                      _ActionChip(
                        icon: Icons.send_rounded,
                        label: 'Share',
                        onTap: onShare,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
