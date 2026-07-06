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
  });

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
    );
  }

  EventRegistration copyWith({bool? attended}) => EventRegistration(
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
      );
}
