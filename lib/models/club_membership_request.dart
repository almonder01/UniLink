import 'package:cloud_firestore/cloud_firestore.dart';

class ClubMembershipRequest {
  final String id;
  final String clubId;
  final String clubName;
  final String userId;
  final String userName;
  final String userEmail;
  final String status; // pending | payment_requested | approved | rejected
  final DateTime createdAt;

  const ClubMembershipRequest({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.createdAt,
  });

  factory ClubMembershipRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['created_at'];
    return ClubMembershipRequest(
      id: doc.id,
      clubId: data['club_id'] as String? ?? '',
      clubName: data['club_name'] as String? ?? 'Club',
      userId: data['user_id'] as String? ?? '',
      userName: data['user_name'] as String? ?? 'Student',
      userEmail: data['user_email'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isPaymentRequested => status == 'payment_requested';
}
