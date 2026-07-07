part of '../club_detail_screen.dart';

class _PostsTab extends StatelessWidget {
  final List<PostModel> posts;
  final ValueChanged<PostModel> onShare;
  const _PostsTab({required this.posts, required this.onShare});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyTabState(
          icon: Icons.chat_bubble_outline_rounded, message: 'No posts yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PostCard(
          post: posts[i],
          onShare: () => onShare(posts[i]),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: posts[i])),
          ),
        ),
      ),
    );
  }
}
