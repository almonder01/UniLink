part of '../home_screen.dart';

class _HomePostsSection extends StatelessWidget {
  final List<PostModel> posts;
  final bool hasMore;
  final bool hasAnyClubContext;
  final String userId;
  final Set<String> savedPostIds;
  final VoidCallback onLoadMore;
  final ValueChanged<PostModel> onOpenPost;
  final ValueChanged<PostModel> onLike;
  final ValueChanged<PostModel> onComment;
  final ValueChanged<PostModel> onSave;
  final ValueChanged<PostModel> onShare;
  final ValueChanged<String> onClubTap;

  const _HomePostsSection({
    required this.posts,
    required this.hasMore,
    required this.hasAnyClubContext,
    required this.userId,
    required this.savedPostIds,
    required this.onLoadMore,
    required this.onOpenPost,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
    required this.onClubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          hasAnyClubContext ? 'From your clubs' : 'Discover clubs',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (posts.isEmpty)
          _EmptyFeed()
        else ...[
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                post: post,
                isLiked: post.likedUserIds.contains(userId),
                isSaved: savedPostIds.contains(post.id),
                onLike: () => onLike(post),
                onComment: () => onComment(post),
                onSave: () => onSave(post),
                onShare: () => onShare(post),
                onClubTap: () => onClubTap(post.clubId),
                onTap: () => onOpenPost(post),
              ),
            ),
          ),
          if (hasMore)
            Center(
              child: OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more posts'),
              ),
            ),
        ],
      ],
    );
  }
}
