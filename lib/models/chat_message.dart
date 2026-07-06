import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoBase64;
  final String? senderGender;
  final String text;
  final String? attachmentType; // post | event
  final String? attachmentId;
  final String? attachmentTitle;
  final String? attachmentSubtitle;
  final String? attachmentClubId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoBase64,
    this.senderGender,
    required this.text,
    this.attachmentType,
    this.attachmentId,
    this.attachmentTitle,
    this.attachmentSubtitle,
    this.attachmentClubId,
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['created_at'];
    return ChatMessage(
      id: doc.id,
      senderId: data['sender_id'] as String? ?? '',
      senderName: data['sender_name'] as String? ?? 'Student',
      senderPhotoBase64: data['sender_photo_base64'] as String?,
      senderGender: data['sender_gender'] as String?,
      text: data['text'] as String? ?? '',
      attachmentType: data['attachment_type'] as String?,
      attachmentId: data['attachment_id'] as String?,
      attachmentTitle: data['attachment_title'] as String?,
      attachmentSubtitle: data['attachment_subtitle'] as String?,
      attachmentClubId: data['attachment_club_id'] as String?,
      createdAt:
          createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
