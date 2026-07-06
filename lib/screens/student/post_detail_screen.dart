import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../services/post_interaction_service.dart';
import '../../services/saved_post_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/identity_avatar.dart';
import '../../widgets/media_gallery.dart';
import '../../widgets/post_comment_sheet.dart';
import '../chat/share_to_chat_sheet.dart';
import 'club_detail_screen.dart';

part 'post_detail/post_action_button.dart';
part 'post_detail/post_club_row.dart';
part 'post_detail/post_detail_content.dart';
part 'post_detail/post_detail_header.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _initialized = false;
  bool _liked = false;
  bool _saved = false;
  late int _likeCount;
  late int _commentCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    _liked = userId != null && widget.post.likedUserIds.contains(userId);
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _initialized = true;
    if (userId != null) _loadSavedState(userId);
  }

  Future<void> _loadSavedState(String userId) async {
    final ids = await SavedPostService().getSavedPostIds(userId);
    if (!mounted) return;
    setState(() => _saved = ids.contains(widget.post.id));
  }

  Future<void> _toggleLike() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });

    try {
      await PostInteractionService().toggleLike(
        postId: widget.post.id,
        userId: userId,
        currentlyLiked: wasLiked,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _showComments() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PostCommentSheet(
        post: widget.post.copyWith(commentCount: _commentCount),
        user: user,
        onCommentAdded: () {
          if (mounted) setState(() => _commentCount += 1);
        },
        onCommentDeleted: () {
          if (mounted && _commentCount > 0) {
            setState(() => _commentCount -= 1);
          }
        },
      ),
    );
  }

  Future<void> _toggleSaved() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final wasSaved = _saved;
    setState(() => _saved = !wasSaved);

    try {
      await SavedPostService().toggleSaved(
        userId: user.id,
        postId: widget.post.id,
        currentlySaved: wasSaved,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saved = wasSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sharePost() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await ShareToChatSheet.showPost(context, post: widget.post, user: user);
  }

  void _openClub() {
    final club = context.read<ClubProvider>().getById(widget.post.clubId);
    if (club == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coverColor = Color(int.parse(widget.post.coverColor, radix: 16));
    final logoColor = widget.post.clubLogoColor != null
        ? Color(int.parse(widget.post.clubLogoColor!, radix: 16))
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _PostDetailHeader(post: widget.post, coverColor: coverColor),
          SliverToBoxAdapter(
            child: _PostDetailContent(
              post: widget.post,
              logoColor: logoColor,
              liked: _liked,
              saved: _saved,
              likeCount: _likeCount,
              commentCount: _commentCount,
              onOpenClub: _openClub,
              onToggleLike: _toggleLike,
              onShowComments: _showComments,
              onToggleSaved: _toggleSaved,
              onSharePost: _sharePost,
            ),
          ),
        ],
      ),
    );
  }
}
