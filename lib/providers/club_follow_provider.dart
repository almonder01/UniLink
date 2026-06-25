import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClubFollowProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final Map<String, Set<String>> _followMap = {};
  String? _lastLoadedUserId;

  Set<String> _idsFor(String userId) =>
      _followMap.putIfAbsent(userId, () => {});

  bool isFollowing(String userId, String clubId) =>
      _followMap[userId]?.contains(clubId) ?? false;

  void follow(String userId, String clubId) {
    _idsFor(userId).add(clubId);
    notifyListeners();
    _db.collection('user_follows').doc(userId).set({
      'club_ids': FieldValue.arrayUnion([clubId]),
    }, SetOptions(merge: true)).catchError((_) {});
    _db.collection('clubs').doc(clubId).update({
      'member_count': FieldValue.increment(1),
    }).catchError((_) {});
  }

  void unfollow(String userId, String clubId) {
    _idsFor(userId).remove(clubId);
    notifyListeners();
    _db.collection('user_follows').doc(userId).update({
      'club_ids': FieldValue.arrayRemove([clubId]),
    }).catchError((_) {});
    _db.collection('clubs').doc(clubId).update({
      'member_count': FieldValue.increment(-1),
    }).catchError((_) {});
  }

  Set<String> getFollowedIds(String userId) =>
      Set.unmodifiable(_followMap[userId] ?? {});

  void loadFollowsIfNeeded(String? userId) {
    if (userId == null || userId == _lastLoadedUserId) return;
    _lastLoadedUserId = userId;
    _db.collection('user_follows').doc(userId).get().then((doc) {
      if (!doc.exists) return;
      final ids = List<String>.from(doc.data()?['club_ids'] ?? []);
      _followMap[userId] = Set.from(ids);
      notifyListeners();
    }).catchError((_) {});
  }
}
