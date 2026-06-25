import 'dart:async';
import 'package:flutter/material.dart';
import '../models/club.dart';
import '../services/club_service.dart';

class ClubProvider extends ChangeNotifier {
  List<ClubModel> _clubs = [];
  bool _loading = true;
  StreamSubscription<List<ClubModel>>? _sub;

  List<ClubModel> get clubs => _clubs;
  bool get loading => _loading;

  ClubModel? getById(String id) {
    try {
      return _clubs.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void startListening() {
    _sub?.cancel();
    _sub = ClubService().clubsStream().listen((clubs) {
      _clubs = clubs;
      _loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
