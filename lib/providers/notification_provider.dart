import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  String? _userId;
  StreamSubscription<List<NotificationModel>>? _sub;
  List<NotificationModel> _items = [];

  List<NotificationModel> get notifications => _items;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  void setUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _items = [];
    notifyListeners();
    if (userId == null) return;
    _sub = NotificationService().streamForUser(userId).listen((items) {
      _items = items;
      notifyListeners();
    });
  }

  Future<void> markAllRead() async {
    if (_userId == null) return;
    await NotificationService().markAllRead(_userId!);
  }

  Future<void> markRead(String notifId) async {
    if (_userId == null) return;
    await NotificationService().markRead(_userId!, notifId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
