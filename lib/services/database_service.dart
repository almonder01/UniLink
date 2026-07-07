import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostPage {
  final List<PostModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;

  const PostPage({
    required this.posts,
    required this.cursor,
    required this.hasMore,
  });
}

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

  Future<List<PostModel>> getRecentPosts({int limit = 60}) async {
    final snap = await _fs
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    final posts =
        snap.docs.map((d) => PostModel.fromFirestoreMap(d.data())).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<PostPage> getRecentPostsPage({
    int limit = 10,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    var query = _fs
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit + 1);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final visibleDocs = snap.docs.take(limit).toList();
    final posts =
        visibleDocs.map((d) => PostModel.fromFirestoreMap(d.data())).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return PostPage(
      posts: posts,
      cursor: visibleDocs.isEmpty ? startAfter : visibleDocs.last,
      hasMore: snap.docs.length > limit,
    );
  }

  Future<PostModel?> getPostById(String id) async {
    final doc = await _fs.collection('posts').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PostModel.fromFirestoreMap(doc.data()!);
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
