import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_comment.dart';
import '../models/user.dart';

class PostInteractionService {
  static final PostInteractionService _instance =
      PostInteractionService._internal();
  factory PostInteractionService() => _instance;
  PostInteractionService._internal();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _postRef(String postId) =>
      _db.collection('posts').doc(postId);

  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) =>
      _postRef(postId).collection('comments');

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    await _postRef(postId).update({
      'likedUserIds': currentlyLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
      'likeCount': FieldValue.increment(currentlyLiked ? -1 : 1),
    });
  }

  Future<void> addComment({
    required String postId,
    required UserModel user,
    required String text,
  }) async {
    final commentRef = _commentsRef(postId).doc();
    final comment = PostComment(
      id: commentRef.id,
      postId: postId,
      userId: user.id,
      userName: user.name,
      userPhotoBase64: user.photoBase64,
      userGender: user.gender,
      text: text,
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((tx) async {
      tx.set(commentRef, comment.toMap());
      tx.update(_postRef(postId), {'commentCount': FieldValue.increment(1)});
    });
  }

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    await _commentsRef(postId).doc(commentId).update({
      'text': cleanText,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _db.runTransaction((tx) async {
      final commentRef = _commentsRef(postId).doc(commentId);
      final commentDoc = await tx.get(commentRef);
      if (!commentDoc.exists) return;
      tx.delete(commentRef);
      tx.update(_postRef(postId), {'commentCount': FieldValue.increment(-1)});
    });
  }

  Stream<List<PostComment>> commentsStream(String postId) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PostComment.fromMap(d.data())).toList());
  }
}
