import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club.dart';
import '../models/club_payment_receipt.dart';
import '../models/user.dart';
import 'club_membership_service.dart';
import 'notification_service.dart';

class ClubPaymentService {
  static final ClubPaymentService _instance = ClubPaymentService._internal();
  factory ClubPaymentService() => _instance;
  ClubPaymentService._internal();

  final _db = FirebaseFirestore.instance;
  final _membershipService = ClubMembershipService();

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('club_payment_requests');

  CollectionReference<Map<String, dynamic>> get _receipts =>
      _db.collection('club_payment_receipts');

  String amountLabel(double amount, String currency) =>
      currency == 'USD' ? '\$${amount.toStringAsFixed(2)}' : 'RM ${amount.toStringAsFixed(2)}';

  Future<void> sendMonthlyRequestToMembers({
    required ClubModel club,
    required UserModel manager,
    required double amount,
    required String currency,
    required String message,
  }) async {
    final memberIds = await _membershipService.memberIdsForClub(club.id);
    await _createRequest(
      club: club,
      manager: manager,
      amount: amount,
      currency: currency,
      message: message,
      targetUserIds: memberIds,
      targetType: 'members',
    );
  }

  Future<void> sendMonthlyRequestByEmail({
    required ClubModel club,
    required UserModel manager,
    required double amount,
    required String currency,
    required String message,
    required String email,
  }) async {
    final snap = await _db
        .collection('profiles')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw Exception('No user found with that email.');
    }
    await _createRequest(
      club: club,
      manager: manager,
      amount: amount,
      currency: currency,
      message: message,
      targetUserIds: [snap.docs.first.id],
      targetType: 'single',
    );
  }

  Future<void> _createRequest({
    required ClubModel club,
    required UserModel manager,
    required double amount,
    required String currency,
    required String message,
    required List<String> targetUserIds,
    required String targetType,
  }) async {
    final cleanTargets = targetUserIds.toSet().toList();
    if (cleanTargets.isEmpty) {
      throw Exception('No members found for this payment request.');
    }
    final ref = _requests.doc();
    final label = amountLabel(amount, currency);
    await ref.set({
      'club_id': club.id,
      'club_name': club.name,
      'amount': amount,
      'currency': currency,
      'amount_label': label,
      'message': message.trim(),
      'target_type': targetType,
      'target_user_ids': cleanTargets,
      'created_by': manager.id,
      'created_at': FieldValue.serverTimestamp(),
      'month_key': _monthKey(DateTime.now()),
    });

    for (final userId in cleanTargets) {
      await NotificationService().sendClubPaymentRequest(
        userId: userId,
        clubId: club.id,
        clubName: club.name,
        requestId: ref.id,
        amountLabel: label,
      );
    }
  }

  Future<void> uploadReceipt({
    required String requestId,
    required UserModel user,
    required String receiptBase64,
  }) async {
    if (receiptBase64.trim().isEmpty) return;
    final request = await _requests.doc(requestId).get();
    if (!request.exists) throw Exception('Payment request not found.');
    final data = request.data()!;
    final receiptId = '${requestId}_${user.id}';
    final now = DateTime.now();
    await _receipts.doc(receiptId).set({
      'request_id': requestId,
      'club_id': data['club_id'] as String? ?? '',
      'user_id': user.id,
      'user_name': user.name,
      'user_email': user.email,
      'receipt_base64': receiptBase64,
      'submitted_at': FieldValue.serverTimestamp(),
      'day_key': _dayKey(now),
      'month_key': _monthKey(now),
    }, SetOptions(merge: true));
  }

  Future<ClubPaymentStats> statsForClub(String clubId) async {
    final requestsSnap =
        await _requests.where('club_id', isEqualTo: clubId).get();
    final receiptsSnap =
        await _receipts.where('club_id', isEqualTo: clubId).get();
    final expected = requestsSnap.docs.fold<int>(0, (total, doc) {
      final ids = List<String>.from(doc.data()['target_user_ids'] ?? const []);
      return total + ids.length;
    });
    final receipts = receiptsSnap.docs
        .map((doc) => ClubPaymentReceipt.fromFirestore(doc))
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    final todayKey = _dayKey(DateTime.now());
    final monthKey = _monthKey(DateTime.now());

    return ClubPaymentStats(
      requestCount: requestsSnap.size,
      expectedReceipts: expected,
      submittedReceipts: receipts.length,
      pendingReceipts: (expected - receipts.length).clamp(0, expected),
      todayReceipts:
          receiptsSnap.docs.where((doc) => doc.data()['day_key'] == todayKey).length,
      monthReceipts:
          receiptsSnap.docs.where((doc) => doc.data()['month_key'] == monthKey).length,
      recentReceipts: receipts.take(8).toList(),
    );
  }

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
