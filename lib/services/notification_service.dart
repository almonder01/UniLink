import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference _col(String userId) =>
      _db.collection('notifications').doc(userId).collection('items');

  Stream<List<NotificationModel>> streamForUser(String userId) => _col(userId)
      .orderBy('time', descending: true)
      .snapshots()
      .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());

  Future<void> markRead(String userId, String notifId) =>
      _col(userId).doc(notifId).update({'is_read': true});

  Future<void> markAllRead(String userId) async {
    final unread = await _col(userId).where('is_read', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  /// Writes a notification to every user who follows [clubId].
  /// Queries `user_follows/{userId}.club_ids` for matching followers.
  Future<void> notifyFollowers({
    required String clubId,
    required String title,
    required String body,
    required String type,
    required String color,
    required String refId,
  }) async {
    final follows = await _db
        .collection('user_follows')
        .where('club_ids', arrayContains: clubId)
        .get();
    if (follows.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in follows.docs) {
      final ref = _col(doc.id).doc();
      batch.set(ref, {
        'title': title,
        'body': body,
        'type': type,
        'color': color,
        'club_id': clubId,
        'ref_id': refId,
        'time': FieldValue.serverTimestamp(),
        'is_read': false,
      });
    }
    await batch.commit();
  }
}
