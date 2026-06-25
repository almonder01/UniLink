class PostModel {
  final String id;
  final String title;
  final String description;
  final String clubId;
  final String clubName;
  final String? clubLogoColor;
  final String coverColor;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.clubId,
    required this.clubName,
    this.clubLogoColor,
    required this.coverColor,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'title': title,
        'description': description,
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoColor': clubLogoColor ?? 'FF6366F1',
        'coverColor': coverColor,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PostModel.fromFirestoreMap(Map<String, dynamic> map) => PostModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        clubId: map['clubId'] as String,
        clubName: map['clubName'] as String,
        clubLogoColor: map['clubLogoColor'] as String?,
        coverColor: map['coverColor'] as String? ?? 'FF6366F1',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  PostModel copyWith({String? title, String? description, String? coverColor}) =>
      PostModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        clubId: clubId,
        clubName: clubName,
        clubLogoColor: clubLogoColor,
        coverColor: coverColor ?? this.coverColor,
        createdAt: createdAt,
      );
}
