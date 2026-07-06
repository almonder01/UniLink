import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';
import 'database_service.dart';

class SavedPostService {
  static final SavedPostService _instance = SavedPostService._internal();
  factory SavedPostService() => _instance;
  SavedPostService._internal();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _db.collection('user_saved_posts').doc(userId);

  Future<Set<String>> getSavedPostIds(String userId) async {
    if (userId.isEmpty) return {};
    final doc = await _doc(userId).get();
    final ids = List<String>.from(doc.data()?['post_ids'] ?? const []);
    return ids.toSet();
  }

  Future<void> savePost(String userId, String postId) async {
    await _doc(userId).set({
      'post_ids': FieldValue.arrayUnion([postId]),
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> unsavePost(String userId, String postId) async {
    await _doc(userId).set({
      'post_ids': FieldValue.arrayRemove([postId]),
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleSaved({
    required String userId,
    required String postId,
    required bool currentlySaved,
  }) {
    return currentlySaved ? unsavePost(userId, postId) : savePost(userId, postId);
  }

  Future<List<PostModel>> getSavedPosts(String userId) async {
    final ids = await getSavedPostIds(userId);
    if (ids.isEmpty) return [];
    return DatabaseService().getPostsByIds(ids.toList());
  }
}
