class EventRegistration {
  final String id;
  final String eventId;
  final String eventTitle;
  final String clubId;
  final String userId;
  final String userName;
  final String userEmail;
  final String studentId;
  final DateTime registeredAt;
  final bool attended;
  final String status; // pending | approved | rejected | cancelled
  final String? paymentReceiptBase64;
  final double? paymentAmount;
  final String? paymentCurrency;
  final String? requirementTextResponse;
  final String? requirementFileBase64;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.clubId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.studentId,
    required this.registeredAt,
    this.attended = false,
    this.status = 'approved',
    this.paymentReceiptBase64,
    this.paymentAmount,
    this.paymentCurrency,
    this.requirementTextResponse,
    this.requirementFileBase64,
  });

  bool get isActive => status != 'rejected' && status != 'cancelled';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';

  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'clubId': clubId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'studentId': studentId,
        'registeredAt': registeredAt.toIso8601String(),
        'attended': attended,
        'status': status,
        if (paymentReceiptBase64 != null)
          'paymentReceiptBase64': paymentReceiptBase64,
        if (paymentAmount != null) 'paymentAmount': paymentAmount,
        if (paymentCurrency != null) 'paymentCurrency': paymentCurrency,
        if (requirementTextResponse != null)
          'requirementTextResponse': requirementTextResponse,
        if (requirementFileBase64 != null)
          'requirementFileBase64': requirementFileBase64,
      };

  factory EventRegistration.fromMap(Map<String, dynamic> map) {
    return EventRegistration(
      id: map['id'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      eventTitle: map['eventTitle'] as String? ?? '',
      clubId: map['clubId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Unknown',
      userEmail: map['userEmail'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      registeredAt: DateTime.tryParse(map['registeredAt'] as String? ?? '') ??
          DateTime.now(),
      attended: map['attended'] as bool? ?? false,
      status: map['status'] as String? ?? 'approved',
      paymentReceiptBase64: map['paymentReceiptBase64'] as String?,
      paymentAmount: (map['paymentAmount'] as num?)?.toDouble(),
      paymentCurrency: map['paymentCurrency'] as String?,
      requirementTextResponse: map['requirementTextResponse'] as String?,
      requirementFileBase64: map['requirementFileBase64'] as String?,
    );
  }

  EventRegistration copyWith({
    bool? attended,
    String? status,
    String? paymentReceiptBase64,
    String? requirementTextResponse,
    String? requirementFileBase64,
  }) =>
      EventRegistration(
        id: id,
        eventId: eventId,
        eventTitle: eventTitle,
        clubId: clubId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        studentId: studentId,
        registeredAt: registeredAt,
        attended: attended ?? this.attended,
        status: status ?? this.status,
        paymentReceiptBase64: paymentReceiptBase64 ?? this.paymentReceiptBase64,
        paymentAmount: paymentAmount,
        paymentCurrency: paymentCurrency,
        requirementTextResponse:
            requirementTextResponse ?? this.requirementTextResponse,
        requirementFileBase64:
            requirementFileBase64 ?? this.requirementFileBase64,
      );
}
