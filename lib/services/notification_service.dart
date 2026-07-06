import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club.dart';
import '../models/notification_model.dart';
import '../models/club_room.dart';
import '../models/user.dart';
import 'club_membership_service.dart';

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

  Future<void> sendRoomInvite({
    required String userId,
    required String senderName,
    required ClubModel club,
    required ClubRoom room,
  }) async {
    await _col(userId).add({
      'title': '${club.name} room invite',
      'body': '$senderName invited you to join ${room.name}.',
      'type': 'room_invite',
      'color': club.logoColor,
      'club_id': club.id,
      'ref_id': room.id,
      'room_name': room.name,
      'time': FieldValue.serverTimestamp(),
      'is_read': false,
    });
  }

  Future<void> sendEventInviteToFollowers({
    required ClubModel club,
    required String eventId,
    required String eventTitle,
  }) async {
    await notifyFollowers(
      clubId: club.id,
      title: 'Event invitation from ${club.name}',
      body: eventTitle,
      type: 'event_invite',
      color: club.logoColor,
      refId: eventId,
    );
  }

  Future<void> sendEventInviteByEmail({
    required ClubModel club,
    required String eventId,
    required String eventTitle,
    required String email,
  }) async {
    final snap = await _db
        .collection('profiles')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw Exception('No user found with that email.');
    }
    await _col(snap.docs.first.id).add({
      'title': 'Event invitation from ${club.name}',
      'body': eventTitle,
      'type': 'event_invite',
      'color': club.logoColor,
      'club_id': club.id,
      'ref_id': eventId,
      'time': FieldValue.serverTimestamp(),
      'is_read': false,
    });
  }

  Future<void> sendEventRegistrationStatus({
    required String userId,
    required String eventTitle,
    required String clubId,
    required String eventId,
    required String status,
    String? message,
  }) async {
    final statusLabel = switch (status) {
      'approved' => 'approved',
      'rejected' => 'rejected',
      'cancelled' => 'cancelled',
      _ => 'updated',
    };
    await _col(userId).add({
      'title': 'Event registration $statusLabel',
      'body': message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'Your registration for $eventTitle was $statusLabel.',
      'type': 'event_registration',
      'color': status == 'approved' ? 'FF22C55E' : 'FFEF4444',
      'club_id': clubId,
      'ref_id': eventId,
      'time': FieldValue.serverTimestamp(),
      'is_read': false,
    });
  }

  Future<void> sendClubPaymentRequest({
    required String userId,
    required String clubId,
    required String clubName,
    required String requestId,
    required String amountLabel,
  }) async {
    await _col(userId).add({
      'title': '$clubName payment request',
      'body': 'Please upload your receipt for $amountLabel.',
      'type': 'club_payment_request',
      'color': 'FF14B8A6',
      'club_id': clubId,
      'ref_id': requestId,
      'time': FieldValue.serverTimestamp(),
      'is_read': false,
    });
  }

  Future<void> sendMembershipRequestStatus({
    required String userId,
    required ClubModel club,
    required String status,
  }) async {
    final approved = status == 'approved';
    await _col(userId).add({
      'title': '${club.name} membership ${approved ? 'approved' : 'updated'}',
      'body': approved
          ? 'You are now a member of ${club.name}.'
          : 'Your membership request for ${club.name} was rejected.',
      'type': 'club',
      'color': club.logoColor,
      'club_id': club.id,
      'ref_id': club.id,
      'time': FieldValue.serverTimestamp(),
      'is_read': false,
    });
  }

  Future<void> sendDirectMessageNotification({
    required String recipientId,
    required UserModel sender,
    required String chatId,
    required String preview,
  }) async {
    final shouldNotify = await _shouldNotifyDirectMessage(
      recipientId: recipientId,
      sender: sender,
    );
    if (!shouldNotify) return;

    await _col(recipientId).add({
      'title': 'Message from ${sender.name}',
      'body': preview.trim().isEmpty ? 'Sent an attachment.' : preview.trim(),
      'type': 'direct_message',
      'color': 'FF14B8A6',
      'club_id': '',
      'ref_id': chatId,
      'time': FieldValue.serverTimestamp(),
      'is_read': false,
    });
  }

  Future<bool> _shouldNotifyDirectMessage({
    required String recipientId,
    required UserModel sender,
  }) async {
    final doc = await _db.collection('profiles').doc(recipientId).get();
    final data = doc.data();
    if (data == null) return true;
    if (data['notify_chat_messages'] == false) return false;

    final senderIsManager =
        sender.role == 'manager' || (sender.managedClubId ?? '').isNotEmpty;
    if (senderIsManager) {
      return data['notify_chat_from_managers'] as bool? ?? true;
    }

    final sharesClub = await ClubMembershipService().usersShareMembership(
      sender.id,
      recipientId,
    );
    if (sharesClub) {
      return data['notify_chat_from_members'] as bool? ?? true;
    }

    return data['notify_chat_from_everyone'] as bool? ?? true;
  }
}
