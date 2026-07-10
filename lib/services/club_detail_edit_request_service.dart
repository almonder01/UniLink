import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club.dart';
import '../models/user.dart';
import 'notification_service.dart';

enum ClubDetailEditRequestResult {
  requested,
  alreadyPending,
  noAdmins,
}

class ClubDetailEditField {
  static const String name = 'name';
  static const String description = 'description';
  static const String logo = 'logo';

  static const List<String> details = [name, description];
  static const List<String> all = [name, description, logo];

  static List<String> fromData(Object? value) {
    if (value is Iterable) return normalize(value.cast<Object?>());
    return normalize(null);
  }

  static List<String> normalize(Iterable<Object?>? fields) {
    final selected = fields == null
        ? details.toSet()
        : fields.whereType<String>().toSet();
    final normalized =
        all.where((field) => selected.contains(field)).toList(growable: false);
    return normalized.isEmpty ? List<String>.from(details) : normalized;
  }

  static String label(String field) {
    return switch (field) {
      name => 'club name',
      description => 'description',
      logo => 'logo',
      _ => field,
    };
  }

  static String describe(Iterable<String> fields) {
    final labels = normalize(fields).map(label).toList(growable: false);
    if (labels.length == 1) return labels.first;
    if (labels.length == 2) return '${labels.first} and ${labels.last}';
    return '${labels.take(labels.length - 1).join(', ')}, and ${labels.last}';
  }
}

class ClubDetailEditPermission {
  final DateTime expiresAt;
  final List<String> fields;

  const ClubDetailEditPermission({
    required this.expiresAt,
    required this.fields,
  });

  bool allows(String field) => fields.contains(field);
  bool get canEditName => allows(ClubDetailEditField.name);
  bool get canEditDescription => allows(ClubDetailEditField.description);
  bool get canEditLogo => allows(ClubDetailEditField.logo);
}

class ClubDetailEditRequest {
  final String id;
  final String clubId;
  final String clubName;
  final String managerId;
  final String managerName;
  final String status;
  final List<String> fields;
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
    required this.fields,
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
      fields: ClubDetailEditField.fromData(data['fields']),
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
    final permission = await activePermission(
      clubId: clubId,
      managerId: managerId,
    );
    return permission?.expiresAt;
  }

  Future<ClubDetailEditPermission?> activePermission({
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
    return ClubDetailEditPermission(
      expiresAt: expiresAt,
      fields: ClubDetailEditField.fromData(data['fields']),
    );
  }

  Future<ClubDetailEditRequest?> requestById(String requestId) async {
    final doc = await _requests.doc(requestId).get();
    return doc.exists ? ClubDetailEditRequest.fromFirestore(doc) : null;
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
    List<String> fields = ClubDetailEditField.details,
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
    final requestedFields = ClubDetailEditField.normalize(fields);
    final fieldSummary = ClubDetailEditField.describe(requestedFields);

    await requestRef.set({
      'id': requestId,
      'club_id': club.id,
      'club_name': club.name,
      'color': club.logoColor,
      'manager_id': manager.id,
      'manager_name': manager.name,
      'fields': requestedFields,
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
        'title': 'Club profile edit request',
        'body': existingPending
            ? '${manager.name} is still waiting for temporary access to edit '
                '$fieldSummary for ${club.name}.'
            : '${manager.name} requested temporary access to edit '
                '$fieldSummary for ${club.name}.',
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
      fields: ClubDetailEditField.fromData(data['fields']),
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
    List<String> fields = ClubDetailEditField.details,
  }) async {
    final expiresAt = minutes == null
        ? DateTime(9999, 12, 31, 23, 59)
        : DateTime.now().add(Duration(minutes: minutes));
    final expiresTimestamp = Timestamp.fromDate(expiresAt);
    final grantedFields = ClubDetailEditField.normalize(fields);
    final fieldSummary = ClubDetailEditField.describe(grantedFields);
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
        'fields': grantedFields,
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
        'fields': grantedFields,
        'is_permanent': minutes == null,
        'expires_at': expiresTimestamp,
        'updated_at': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();

    await NotificationService().sendToUser(
      userId: managerId,
      title: '$clubName profile unlocked',
      body: minutes == null
          ? 'You can edit the $fieldSummary permanently.'
          : 'You can edit the $fieldSummary for $minutes minutes.',
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
      title: '$clubName profile locked',
      body: 'University admin locked club profile editing.',
      type: 'club_detail_edit_permission',
      color: 'FFEF4444',
      clubId: clubId,
      refId: clubId,
    );
  }
}
