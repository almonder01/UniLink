import 'package:cloud_firestore/cloud_firestore.dart';

class ClubPaymentReceipt {
  final String id;
  final String requestId;
  final String clubId;
  final String userId;
  final String userName;
  final String userEmail;
  final String receiptBase64;
  final DateTime submittedAt;

  const ClubPaymentReceipt({
    required this.id,
    required this.requestId,
    required this.clubId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.receiptBase64,
    required this.submittedAt,
  });

  factory ClubPaymentReceipt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final submittedAt = data['submitted_at'];
    return ClubPaymentReceipt(
      id: doc.id,
      requestId: data['request_id'] as String? ?? '',
      clubId: data['club_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      userName: data['user_name'] as String? ?? 'Student',
      userEmail: data['user_email'] as String? ?? '',
      receiptBase64: data['receipt_base64'] as String? ?? '',
      submittedAt:
          submittedAt is Timestamp ? submittedAt.toDate() : DateTime.now(),
    );
  }
}

class ClubPaymentStats {
  final int requestCount;
  final int expectedReceipts;
  final int submittedReceipts;
  final int pendingReceipts;
  final int todayReceipts;
  final int monthReceipts;
  final List<ClubPaymentReceipt> recentReceipts;

  const ClubPaymentStats({
    required this.requestCount,
    required this.expectedReceipts,
    required this.submittedReceipts,
    required this.pendingReceipts,
    required this.todayReceipts,
    required this.monthReceipts,
    required this.recentReceipts,
  });
}
