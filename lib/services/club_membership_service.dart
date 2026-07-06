import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club.dart';

class ClubMembershipService {
  static final ClubMembershipService _instance =
      ClubMembershipService._internal();
  factory ClubMembershipService() => _instance;
  ClubMembershipService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _memberships =>
      _db.collection('club_memberships');

  String membershipId(String clubId, String userId) => '${clubId}_$userId';

  Future<bool> isMember(String clubId, String userId) async {
    if (clubId.isEmpty || userId.isEmpty) return false;
    final doc = await _memberships.doc(membershipId(clubId, userId)).get();
    return doc.exists;
  }

  Future<void> addMember({
    required ClubModel club,
    required DocumentSnapshot<Map<String, dynamic>> profileDoc,
    required String addedBy,
  }) async {
    final userId = profileDoc.id;
    if (userId == club.managerId) return;
    final ref = _memberships.doc(membershipId(club.id, userId));

    await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) return;

      tx.set(ref, {
        'club_id': club.id,
        'user_id': userId,
        'role': 'member',
        'added_by': addedBy,
        'joined_at': FieldValue.serverTimestamp(),
      });
      tx.update(_db.collection('clubs').doc(club.id), {
        'member_count': FieldValue.increment(1),
      });
    });
  }

  Future<void> removeMember({
    required String clubId,
    required String userId,
  }) async {
    final ref = _memberships.doc(membershipId(clubId, userId));
    await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (!existing.exists) return;
      tx.delete(ref);
      tx.update(_db.collection('clubs').doc(clubId), {
        'member_count': FieldValue.increment(-1),
      });
    });
  }

  Future<List<String>> memberIdsForClub(String clubId) async {
    final snap =
        await _memberships.where('club_id', isEqualTo: clubId).get();
    return snap.docs
        .map((doc) => doc.data()['user_id'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<List<String>> memberClubIdsForUser(String userId) async {
    if (userId.isEmpty) return [];
    final snap =
        await _memberships.where('user_id', isEqualTo: userId).get();
    return snap.docs
        .map((doc) => doc.data()['club_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
  }

  Future<bool> usersShareMembership(String userA, String userB) async {
    if (userA.isEmpty || userB.isEmpty || userA == userB) return false;
    final aClubs = await memberClubIdsForUser(userA);
    if (aClubs.isEmpty) return false;
    final bClubs = await memberClubIdsForUser(userB);
    return bClubs.any(aClubs.contains);
  }

  Future<List<Map<String, dynamic>>> memberProfilesForClub(
    ClubModel club, {
    bool publicOnly = false,
    bool includeManager = true,
  }) async {
    final ids = <String>{};
    ids.addAll(await memberIdsForClub(club.id));
    if (includeManager && (club.managerId ?? '').isNotEmpty) {
      ids.add(club.managerId!);
    }
    if (ids.isEmpty) return [];

    final members = await _profilesForIds(ids.toList());
    final filtered = members.where((member) {
      final isManager = member['uid'] == club.managerId;
      if (isManager) return true;
      if (!publicOnly) return true;
      return member['showInClubMembers'] != false;
    }).map((member) {
      return {
        ...member,
        'role': member['uid'] == club.managerId ? 'Manager' : 'Member',
      };
    }).toList();

    filtered.sort((a, b) {
      if (a['role'] == 'Manager') return -1;
      if (b['role'] == 'Manager') return 1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return filtered;
  }

  Future<List<Map<String, dynamic>>> followerProfilesForClub(
    String clubId, {
    bool publicOnly = false,
  }) async {
    final followsSnap = await _db
        .collection('user_follows')
        .where('club_ids', arrayContains: clubId)
        .get();
    final ids = followsSnap.docs.map((doc) => doc.id).toSet().toList();
    if (ids.isEmpty) return [];

    final followers = await _profilesForIds(ids);
    final filtered = followers.where((follower) {
      if (!publicOnly) return true;
      return follower['showInClubFollowers'] != false;
    }).toList();
    filtered.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return filtered;
  }

  Future<List<Map<String, dynamic>>> _profilesForIds(List<String> ids) async {
    final profiles = <Map<String, dynamic>>[];
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));
      final snap = await _db
          .collection('profiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        profiles.add({
          'uid': doc.id,
          'name': data['name'] as String? ?? 'Student',
          'email': data['email'] as String? ?? '',
          'major': data['major'] as String? ?? '',
          'gender': data['gender'] as String? ?? 'male',
          'photoBase64': data['photo_base64'] as String? ?? '',
          'messagePrivacy': data['message_privacy'] as String? ?? 'everyone',
          'showInClubMembers': data['show_in_club_members'] as bool? ?? true,
          'showInClubFollowers':
              data['show_in_club_followers'] as bool? ?? true,
          'managedClubId': data['managed_club_id'] as String?,
        });
      }
    }
    return profiles;
  }
}
