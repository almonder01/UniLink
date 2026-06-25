import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'post' | 'event' | 'club'
  final String color;
  final String clubId;
  final String? refId;
  final DateTime time;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.color,
    required this.clubId,
    this.refId,
    required this.time,
    required this.isRead,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['time'];
    return NotificationModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: d['type'] as String? ?? 'post',
      color: d['color'] as String? ?? 'FF6366F1',
      clubId: d['club_id'] as String? ?? '',
      refId: d['ref_id'] as String?,
      time: ts is Timestamp ? ts.toDate() : DateTime.now(),
      isRead: d['is_read'] as bool? ?? false,
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        color: color,
        clubId: clubId,
        refId: refId,
        time: time,
        isRead: isRead ?? this.isRead,
      );
}
