import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static final _fs = FirebaseFirestore.instance;

  Future<void> insertPost(PostModel post) =>
      _fs.collection('posts').doc(post.id).set(post.toFirestoreMap());

  Future<List<PostModel>> getAllPosts() async {
    final snap = await _fs.collection('posts').get();
    final posts =
        snap.docs.map((d) => PostModel.fromFirestoreMap(d.data())).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<List<PostModel>> getPostsByClub(String clubId) async {
    final snap = await _fs
        .collection('posts')
        .where('clubId', isEqualTo: clubId)
        .get();
    final posts =
        snap.docs.map((d) => PostModel.fromFirestoreMap(d.data())).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<List<PostModel>> getPostsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final posts = <PostModel>[];
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));
      final snap = await _fs
          .collection('posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      posts.addAll(
        snap.docs.map((d) => PostModel.fromFirestoreMap(d.data())),
      );
    }
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<void> updatePost(PostModel post) =>
      _fs.collection('posts').doc(post.id).update(post.toFirestoreMap());

  Future<void> deletePost(String id) =>
      _fs.collection('posts').doc(id).delete();
}
