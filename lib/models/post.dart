class PostModel {
  final String id;
  final String title;
  final String description;
  final String clubId;
  final String clubName;
  final String? clubLogoColor;
  final String? clubLogoImageBase64;
  final bool clubShowLogoBackground;
  final String coverColor;
  final String? coverImageBase64;
  final List<String> photoBase64List;
  final DateTime createdAt;
  final List<String> likedUserIds;
  final int likeCount;
  final int commentCount;

  const PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.clubId,
    required this.clubName,
    this.clubLogoColor,
    this.clubLogoImageBase64,
    this.clubShowLogoBackground = true,
    required this.coverColor,
    this.coverImageBase64,
    this.photoBase64List = const [],
    required this.createdAt,
    this.likedUserIds = const [],
    this.likeCount = 0,
    this.commentCount = 0,
  });

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'title': title,
        'description': description,
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoColor': clubLogoColor ?? 'FF6366F1',
        if (clubLogoImageBase64 != null)
          'clubLogoImageBase64': clubLogoImageBase64,
        'clubShowLogoBackground': clubShowLogoBackground,
        'coverColor': coverColor,
        if (coverImageBase64 != null) 'coverImageBase64': coverImageBase64,
        'photoBase64List': photoBase64List,
        'createdAt': createdAt.toIso8601String(),
        'likedUserIds': likedUserIds,
        'likeCount': likeCount,
        'commentCount': commentCount,
      };

  factory PostModel.fromFirestoreMap(Map<String, dynamic> map) => PostModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        clubId: map['clubId'] as String,
        clubName: map['clubName'] as String,
        clubLogoColor: map['clubLogoColor'] as String?,
        clubLogoImageBase64: map['clubLogoImageBase64'] as String?,
        clubShowLogoBackground: map['clubShowLogoBackground'] as bool? ?? true,
        coverColor: map['coverColor'] as String? ?? 'FF6366F1',
        coverImageBase64: map['coverImageBase64'] as String?,
        photoBase64List: List<String>.from(map['photoBase64List'] ?? const []),
        createdAt: DateTime.parse(map['createdAt'] as String),
        likedUserIds: List<String>.from(map['likedUserIds'] ?? const []),
        likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
        commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      );

  PostModel copyWith({
    String? title,
    String? description,
    String? coverColor,
    String? coverImageBase64,
    List<String>? photoBase64List,
    List<String>? likedUserIds,
    int? likeCount,
    int? commentCount,
  }) =>
      PostModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        clubId: clubId,
        clubName: clubName,
        clubLogoColor: clubLogoColor,
        clubLogoImageBase64: clubLogoImageBase64,
        clubShowLogoBackground: clubShowLogoBackground,
        coverColor: coverColor ?? this.coverColor,
        coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
        photoBase64List: photoBase64List ?? this.photoBase64List,
        createdAt: createdAt,
        likedUserIds: likedUserIds ?? this.likedUserIds,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
      );
}
