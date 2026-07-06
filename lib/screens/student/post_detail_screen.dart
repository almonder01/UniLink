import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_interaction_service.dart';
import '../../services/saved_post_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/identity_avatar.dart';
import '../../widgets/media_gallery.dart';
import '../../widgets/post_comment_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverColor = Color(int.parse(widget.post.coverColor, radix: 16));
    final logoColor = widget.post.clubLogoColor != null
        ? Color(int.parse(widget.post.clubLogoColor!, radix: 16))
        : cs.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: coverColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      coverColor,
                      Color.lerp(coverColor, Colors.black, 0.5)!
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.post.coverImageBase64 != null) ...[
                      Base64Image(data: widget.post.coverImageBase64!),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.black.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => showBase64ImagePreview(
                              context,
                              data: widget.post.coverImageBase64!,
                            ),
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF14B8A6).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 5),
                            Text('POST',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club row
                  Row(
                    children: [
                      ClubAvatar(
                        color: logoColor,
                        logoBase64: widget.post.clubLogoImageBase64,
                        showBackground: widget.post.clubShowLogoBackground,
                        size: 40,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post.clubName,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                            DateFormat('EEEE, MMMM d, y')
                                .format(widget.post.createdAt),
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.post.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.post.description,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: cs.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 24),
                  // Photo gallery
                  const Text(
                    'Photos',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  MediaGallery(images: widget.post.photoBase64List),
                  const SizedBox(height: 28),
                  Divider(color: cs.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  // Actions
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _ActionBtn(
                        icon: _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: 'Like',
                        count: _likeCount,
                        color: _liked ? Colors.red : null,
                        onTap: _toggleLike,
                      ),
                      _ActionBtn(
                        icon: Icons.mode_comment_outlined,
                        label: 'Comments',
                        count: _commentCount,
                        onTap: _showComments,
                      ),
                      _ActionBtn(
                        icon: _saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: 'Save',
                        color: _saved ? cs.primary : null,
                        onTap: _toggleSaved,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      this.count,
      this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurface.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            const SizedBox(height: 4),
            Text(count == null ? label : '$count $label',
                style: TextStyle(
                    fontSize: 12,
                    color: effectiveColor,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
