import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/post_comment.dart';
import '../models/user.dart';
import '../services/post_interaction_service.dart';
import 'identity_avatar.dart';

class PostCommentSheet extends StatefulWidget {
  final PostModel post;
  final UserModel user;
  final VoidCallback? onCommentAdded;

  const PostCommentSheet({
    super.key,
    required this.post,
    required this.user,
    this.onCommentAdded,
  });

  @override
  State<PostCommentSheet> createState() => _PostCommentSheetState();
}

class _PostCommentSheetState extends State<PostCommentSheet> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await PostInteractionService().addComment(
        postId: widget.post.id,
        user: widget.user,
        text: text,
      );
      _commentCtrl.clear();
      widget.onCommentAdded?.call();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.post.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<PostComment>>(
                  stream: PostInteractionService()
                      .commentsStream(widget.post.id),
                  builder: (context, snapshot) {
                    final comments = snapshot.data ?? const <PostComment>[];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                      itemCount: comments.length,
                      itemBuilder: (_, index) =>
                          _CommentTile(comment: comments[index]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          prefixIcon: Icon(Icons.comment_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _submitting ? null : _submitComment,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            photoBase64: comment.userPhotoBase64,
            gender: comment.userGender,
            radius: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
