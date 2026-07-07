part of '../post_detail_screen.dart';

class _PostDetailContent extends StatelessWidget {
  final PostModel post;
  final Color logoColor;
  final bool liked;
  final bool saved;
  final int likeCount;
  final int commentCount;
  final bool autoPlayAudio;
  final VoidCallback onOpenClub;
  final VoidCallback onToggleLike;
  final VoidCallback onShowComments;
  final VoidCallback onToggleSaved;
  final VoidCallback onSharePost;

  const _PostDetailContent({
    required this.post,
    required this.logoColor,
    required this.liked,
    required this.saved,
    required this.likeCount,
    required this.commentCount,
    required this.autoPlayAudio,
    required this.onOpenClub,
    required this.onToggleLike,
    required this.onShowComments,
    required this.onToggleSaved,
    required this.onSharePost,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostClubRow(post: post, logoColor: logoColor, onTap: onOpenClub),
          const SizedBox(height: 20),
          Text(
            post.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 14),
          Text(
            post.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 24),
          ContentMediaSection(
            title: post.title,
            youtubeVideoUrl: post.youtubeUrl,
            directVideoUrl: post.videoUrl,
            videoType: post.videoType,
            audioUrl: post.audioUrl,
            audioType: post.audioType,
            audioSubtitle: 'Post music',
            autoPlayAudio: autoPlayAudio,
            headingStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            bottomSpacing: 24,
          ),
          const Text(
            'Photos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          MediaGallery(images: post.photoBase64List),
          const SizedBox(height: 28),
          Divider(color: cs.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 10,
            runSpacing: 8,
            children: [
              _ActionBtn(
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: 'Like',
                count: likeCount,
                color: liked ? Colors.red : null,
                onTap: onToggleLike,
              ),
              _ActionBtn(
                icon: Icons.mode_comment_outlined,
                label: 'Comments',
                count: commentCount,
                onTap: onShowComments,
              ),
              _ActionBtn(
                icon: saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: 'Save',
                color: saved ? cs.primary : null,
                onTap: onToggleSaved,
              ),
              _ActionBtn(
                icon: Icons.send_rounded,
                label: 'Share',
                onTap: onSharePost,
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
