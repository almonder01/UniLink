import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club.dart';
import '../models/club_membership_request.dart';
import '../models/user.dart';
import 'notification_service.dart';

class MembershipRequestService {
  static final MembershipRequestService _instance =
      MembershipRequestService._internal();
  factory MembershipRequestService() => _instance;
  MembershipRequestService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('club_membership_requests');

  String requestId(String clubId, String userId) => '${clubId}_$userId';

  Future<ClubMembershipRequest?> getRequest({
    required String clubId,
    required String userId,
  }) async {
    final doc = await _requests.doc(requestId(clubId, userId)).get();
    return doc.exists ? ClubMembershipRequest.fromFirestore(doc) : null;
  }

  Future<void> requestMembership({
    required ClubModel club,
    required UserModel user,
  }) async {
    final id = requestId(club.id, user.id);
    await _requests.doc(id).set({
      'club_id': club.id,
      'club_name': club.name,
      'user_id': user.id,
      'user_name': user.name,
      'user_email': user.email,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ClubMembershipRequest>> requestsForClub(String clubId) {
    return _requests
        .where('club_id', isEqualTo: clubId)
        .snapshots()
        .map((snap) {
      final requests =
          snap.docs.map(ClubMembershipRequest.fromFirestore).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Future<List<ClubMembershipRequest>> requestsForUser(String userId) async {
    final snap =
        await _requests.where('user_id', isEqualTo: userId).get();
    final requests =
        snap.docs.map(ClubMembershipRequest.fromFirestore).toList();
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  Future<void> approve({
    required ClubModel club,
    required ClubMembershipRequest request,
    required String managerId,
  }) async {
    final membershipId = '${club.id}_${request.userId}';
    await _db.runTransaction((tx) async {
      final membershipRef =
          _db.collection('club_memberships').doc(membershipId);
      final membershipDoc = await tx.get(membershipRef);
      if (!membershipDoc.exists) {
        tx.set(membershipRef, {
          'club_id': club.id,
          'user_id': request.userId,
          'role': 'member',
          'added_by': managerId,
          'joined_at': FieldValue.serverTimestamp(),
        });
        tx.update(_db.collection('clubs').doc(club.id), {
          'member_count': FieldValue.increment(1),
        });
      }
      tx.update(_requests.doc(request.id), {
        'status': 'approved',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
    await NotificationService().sendMembershipRequestStatus(
      userId: request.userId,
      club: club,
      status: 'approved',
    );
  }

  Future<void> reject({
    required ClubModel club,
    required ClubMembershipRequest request,
  }) async {
    await _requests.doc(request.id).update({
      'status': 'rejected',
      'updated_at': FieldValue.serverTimestamp(),
    });
    await NotificationService().sendMembershipRequestStatus(
      userId: request.userId,
      club: club,
      status: 'rejected',
    );
  }

  Future<void> markPaymentRequested(ClubMembershipRequest request) async {
    await _requests.doc(request.id).update({
      'status': 'payment_requested',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
