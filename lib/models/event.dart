class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String clubId;
  final String clubName;
  final String? clubLogoColor;
  final String coverColor;
  final DateTime eventDate;
  bool isRegistered;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.clubId,
    required this.clubName,
    this.clubLogoColor,
    required this.coverColor,
    required this.eventDate,
    this.isRegistered = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoColor': clubLogoColor ?? 'FF6366F1',
        'coverColor': coverColor,
        'eventDate': eventDate.toIso8601String(),
      };

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        location: map['location'] as String,
        clubId: map['clubId'] as String,
        clubName: map['clubName'] as String,
        clubLogoColor: map['clubLogoColor'] as String?,
        coverColor: map['coverColor'] as String? ?? 'FF6366F1',
        eventDate: DateTime.parse(map['eventDate'] as String),
      );

  EventModel copyWith({bool? isRegistered}) => EventModel(
        id: id,
        title: title,
        description: description,
        location: location,
        clubId: clubId,
        clubName: clubName,
        clubLogoColor: clubLogoColor,
        coverColor: coverColor,
        eventDate: eventDate,
        isRegistered: isRegistered ?? this.isRegistered,
      );
}
