import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club.dart';
import '../models/user.dart';
import 'notification_service.dart';

enum ClubDetailEditRequestResult {
  requested,
  alreadyPending,
  noAdmins,
}

class ClubDetailEditRequest {
  final String id;
  final String clubId;
  final String clubName;
  final String managerId;
  final String managerName;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? grantedUntil;

  const ClubDetailEditRequest({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.managerId,
    required this.managerName,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.grantedUntil,
  });

  bool get isPending => status == 'pending';
  bool get isGranted => status == 'granted';

  factory ClubDetailEditRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    DateTime? timestampToDate(Object? value) {
      return value is Timestamp ? value.toDate() : null;
    }

    return ClubDetailEditRequest(
      id: doc.id,
      clubId: data['club_id'] as String? ?? '',
      clubName: data['club_name'] as String? ?? 'Club',
      managerId: data['manager_id'] as String? ?? '',
      managerName: data['manager_name'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: timestampToDate(data['created_at']),
      updatedAt: timestampToDate(data['updated_at']),
      grantedUntil: timestampToDate(data['granted_until']),
    );
  }
}

class ClubDetailEditRequestService {
  static final ClubDetailEditRequestService _i =
      ClubDetailEditRequestService._();
  factory ClubDetailEditRequestService() => _i;
  ClubDetailEditRequestService._();

  static const int defaultGrantMinutes = 10;

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('club_detail_edit_requests');

  DocumentReference<Map<String, dynamic>> _permissionRef({
    required String clubId,
    required String managerId,
  }) {
    return _db
        .collection('club_detail_edit_permissions')
        .doc(clubId)
        .collection('managers')
        .doc(managerId);
  }

  String requestIdFor({required String clubId, required String managerId}) {
    return '${clubId}_$managerId';
  }

  Future<DateTime?> activePermissionExpiresAt({
    required String clubId,
    required String managerId,
  }) async {
    final doc = await _permissionRef(
      clubId: clubId,
      managerId: managerId,
    ).get();
    final data = doc.data();
    if (data == null) return null;
    final ts = data['expires_at'];
    final expiresAt = ts is Timestamp ? ts.toDate() : null;
    if (expiresAt == null || !expiresAt.isAfter(DateTime.now())) return null;
    return expiresAt;
  }

  Future<List<ClubDetailEditRequest>> requestsForManager(
    String managerId,
  ) async {
    final snap = await _requests
        .where('manager_id', isEqualTo: managerId)
        .get();
    final requests =
        snap.docs.map(ClubDetailEditRequest.fromFirestore).toList();
    requests.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime(1970);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    return requests;
  }

  Future<ClubDetailEditRequestResult> requestEditAccess({
    required ClubModel club,
    required UserModel manager,
  }) async {
    final admins = await _db
        .collection('profiles')
        .where('role', isEqualTo: 'admin')
        .get();
    if (admins.docs.isEmpty) return ClubDetailEditRequestResult.noAdmins;

    final requestId = requestIdFor(clubId: club.id, managerId: manager.id);
    final requestRef = _requests.doc(requestId);
    final existing = await requestRef.get();
    final existingPending = existing.exists &&
        existing.data()?['status'] == 'pending';

    await requestRef.set({
      'id': requestId,
      'club_id': club.id,
      'club_name': club.name,
      'color': club.logoColor,
      'manager_id': manager.id,
      'manager_name': manager.name,
      'status': 'pending',
      if (!existing.exists) 'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final batch = _db.batch();
    for (final admin in admins.docs) {
      final notificationRef = _db
          .collection('notifications')
          .doc(admin.id)
          .collection('items')
          .doc();
      batch.set(notificationRef, {
        'title': 'Club details edit request',
        'body': existingPending
            ? '${manager.name} is still waiting for temporary access to edit '
                '${club.name} name and description.'
            : '${manager.name} requested temporary access to edit '
                '${club.name} name and description.',
        'type': 'club_detail_edit_request',
        'color': club.logoColor,
        'club_id': club.id,
        'ref_id': requestId,
        'time': FieldValue.serverTimestamp(),
        'is_read': false,
      });
    }
    await batch.commit();
    return existingPending
        ? ClubDetailEditRequestResult.alreadyPending
        : ClubDetailEditRequestResult.requested;
  }

  Future<DateTime> grantEditAccess({
    required String requestId,
    required String adminId,
    int minutes = defaultGrantMinutes,
  }) async {
    final requestRef = _requests.doc(requestId);
    final request = await requestRef.get();
    final data = request.data();
    if (data == null) {
      throw Exception('Edit request not found.');
    }

    final clubId = data['club_id'] as String? ?? '';
    final clubName = data['club_name'] as String? ?? 'Club';
    final managerId = data['manager_id'] as String? ?? '';
    if (clubId.isEmpty || managerId.isEmpty) {
      throw Exception('Edit request is missing club or manager details.');
    }

    return grantManagerEditAccess(
      clubId: clubId,
      clubName: clubName,
      managerId: managerId,
      adminId: adminId,
      minutes: minutes,
      requestId: requestId,
      managerName: data['manager_name'] as String? ?? '',
      color: data['color'] as String? ?? 'FF22C55E',
    );
  }

  Future<DateTime> grantManagerEditAccess({
    required String clubId,
    required String clubName,
    required String managerId,
    required String adminId,
    required int? minutes,
    String? requestId,
    String managerName = '',
    String color = 'FF22C55E',
  }) async {
    final expiresAt = minutes == null
        ? DateTime(9999, 12, 31, 23, 59)
        : DateTime.now().add(Duration(minutes: minutes));
    final expiresTimestamp = Timestamp.fromDate(expiresAt);
    final effectiveRequestId = requestId?.isNotEmpty == true
        ? requestId!
        : requestIdFor(clubId: clubId, managerId: managerId);
    final batch = _db.batch();

    batch.set(
      _requests.doc(effectiveRequestId),
      {
        'id': effectiveRequestId,
        'club_id': clubId,
        'club_name': clubName,
        'manager_id': managerId,
        if (managerName.isNotEmpty) 'manager_name': managerName,
        'status': 'granted',
        'granted_by': adminId,
        'granted_minutes': minutes,
        'granted_until': expiresTimestamp,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _permissionRef(clubId: clubId, managerId: managerId),
      {
        'club_id': clubId,
        'manager_id': managerId,
        'request_id': effectiveRequestId,
        'granted_by': adminId,
        'is_permanent': minutes == null,
        'expires_at': expiresTimestamp,
        'updated_at': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();

    await NotificationService().sendToUser(
      userId: managerId,
      title: '$clubName details unlocked',
      body: minutes == null
          ? 'You can edit the club name and description permanently.'
          : 'You can edit the club name and description for $minutes minutes.',
      type: 'club_detail_edit_permission',
      color: color,
      clubId: clubId,
      refId: clubId,
    );

    return expiresAt;
  }

  Future<void> revokeManagerEditAccess({
    required String clubId,
    required String clubName,
    required String managerId,
  }) async {
    final batch = _db.batch();
    batch.delete(_permissionRef(clubId: clubId, managerId: managerId));
    batch.set(
      _requests.doc(requestIdFor(clubId: clubId, managerId: managerId)),
      {
        'status': 'locked',
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    await NotificationService().sendToUser(
      userId: managerId,
      title: '$clubName details locked',
      body: 'University admin locked club name and description editing.',
      type: 'club_detail_edit_permission',
      color: 'FFEF4444',
      clubId: clubId,
      refId: clubId,
    );
  }
}
