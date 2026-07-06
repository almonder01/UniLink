import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/club_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> checkAuthState() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _loadProfile(user.uid);
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String role,
    required String gender,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      cred.user?.updateDisplayName(name);
      _currentUser = UserModel(
        id: cred.user!.uid,
        name: name,
        studentId: studentId,
        email: email,
        role: role,
        gender: gender,
      );
      // Write profile in background — don't block navigation
      _db.collection('profiles').doc(cred.user!.uid).set({
        'id': cred.user!.uid,
        'name': name,
        'student_id': studentId,
        'email': email,
        'role': role,
        'gender': gender,
        'cover_color': 'FF6366F1',
        'show_in_club_members': true,
      }).catchError((_) {});
      ClubService().seedIfEmpty().catchError((_) {});
      return role;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        final doc = await _db
            .collection('profiles')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!);
        } else {
          _currentUser = UserModel(
            id: cred.user!.uid,
            name: cred.user?.displayName ?? email.split('@').first,
            studentId: '',
            email: email,
            role: 'student',
          );
        }
      } catch (_) {
        _currentUser = UserModel(
          id: cred.user!.uid,
          name: cred.user?.displayName ?? email.split('@').first,
          studentId: '',
          email: email,
          role: 'student',
        );
      }
      ClubService().seedIfEmpty().catchError((_) {});
      return _currentUser!.role;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? major,
    String? gender,
    String? photoBase64,
    String? coverImageBase64,
    String? coverColor,
    bool? showInClubMembers,
  }) async {
    if (_currentUser == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (major != null) updates['major'] = major;
    if (gender != null) updates['gender'] = gender;
    if (photoBase64 != null) updates['photo_base64'] = photoBase64;
    if (coverImageBase64 != null) {
      updates['cover_image_base64'] = coverImageBase64;
    }
    if (coverColor != null) updates['cover_color'] = coverColor;
    if (showInClubMembers != null) {
      updates['show_in_club_members'] = showInClubMembers;
    }
    if (updates.isEmpty) return;
    await _db.collection('profiles').doc(_currentUser!.id).update(updates);
    _currentUser = _currentUser!.copyWith(
      name: name,
      major: major,
      gender: gender,
      photoBase64: photoBase64,
      coverImageBase64: coverImageBase64,
      coverColor: coverColor,
      showInClubMembers: showInClubMembers,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _loadProfile(String uid, {String fallbackRole = 'student'}) async {
    _isLoading = true;
    notifyListeners();
    final authUser = _auth.currentUser;
    try {
      final doc = await _db
          .collection('profiles')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
      } else {
        _currentUser = UserModel(
          id: uid,
          name: authUser?.displayName ?? authUser?.email?.split('@').first ?? 'User',
          studentId: '',
          email: authUser?.email ?? '',
          role: fallbackRole,
        );
      }
    } catch (_) {
      _currentUser = UserModel(
        id: uid,
        name: authUser?.displayName ?? 'User',
        studentId: '',
        email: authUser?.email ?? '',
        role: fallbackRole,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
