import 'package:flutter/material.dart';
import '../../models/club.dart';
import '../../models/post.dart';
import '../../services/database_service.dart';
import '../../widgets/post_card.dart';
import '../student/post_detail_screen.dart';
import 'create_post_screen.dart';
import 'manager_action_banner.dart';
import 'media_library_screen.dart';
import 'menu_tile.dart';
import 'popup_menu_position.dart';
import 'three_dot_button.dart';

class PostsTab extends StatefulWidget {
  final ClubModel club;
  final ValueChanged<int>? onCountChanged;

  const PostsTab({super.key, required this.club, this.onCountChanged});

  @override
  State<PostsTab> createState() => PostsTabState();
}

class PostsTabState extends State<PostsTab> {
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _reportCount() {
    widget.onCountChanged?.call(_posts.length);
  }

  Future<void> _loadPosts() async {
    final posts = await DatabaseService().getPostsByClub(widget.club.id);
    if (mounted) setState(() => _posts = posts);
    _reportCount();
  }

  Future<void> _deletePost(PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('This post will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await DatabaseService().deletePost(post.id);
    if (!mounted) return;
    setState(() => _posts.remove(post));
    _reportCount();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Post deleted'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _editPost(PostModel post) async {
    final result = await Navigator.push<PostModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          club: widget.club,
          existingPost: post,
        ),
      ),
    );
    if (result != null) _loadPosts();
  }

  void createNewPost() async {
    final result = await Navigator.push<PostModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(club: widget.club),
      ),
    );
    if (result != null) _loadPosts();
  }

  Future<void> _openMediaLibrary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaLibraryScreen(club: widget.club),
      ),
    );
  }

  void _showPostMenu(BuildContext anchorContext, PostModel post) {
    showMenu<String>(
      context: anchorContext,
      position: popupMenuPositionForAnchor(anchorContext),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem(
            value: 'edit',
            child: PopupMenuTile(Icons.edit_outlined, 'Edit')),
        PopupMenuItem(
            value: 'delete',
            child: PopupMenuTile(Icons.delete_outline_rounded, 'Delete',
                color: Colors.red)),
      ],
    ).then((val) {
      if (val == 'edit') _editPost(post);
      if (val == 'delete') _deletePost(post);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.isEmpty ? 2 : _posts.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ManagerActionBanner(
              icon: Icons.perm_media_rounded,
              title: 'Media Library',
              subtitle: 'Reuse uploaded videos and music links',
              tooltip: 'Open media library',
              onPressed: _openMediaLibrary,
              padding: EdgeInsets.zero,
            ),
          );
        }
        if (_posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: cs.onSurface.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'No posts yet. Tap + to create one.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }
        final post = _posts[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              PostCard(
                post: post,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: post),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: ThreeDotButton(
                  onTap: (buttonContext) =>
                      _showPostMenu(buttonContext, post),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
