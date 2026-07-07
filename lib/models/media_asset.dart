class MediaAsset {
  final String id;
  final String clubId;
  final String name;
  final String url;
  final String mediaKind;
  final String sourceType;
  final String? createdBy;
  final DateTime createdAt;

  const MediaAsset({
    required this.id,
    required this.clubId,
    required this.name,
    required this.url,
    required this.mediaKind,
    required this.sourceType,
    this.createdBy,
    required this.createdAt,
  });

  bool get isVideo => mediaKind == 'video';
  bool get isAudio => mediaKind == 'audio';
  bool get isYouTube => sourceType == 'youtube';

  String get sourceLabel {
    if (sourceType == 'youtube') return 'YouTube';
    if (sourceType == 'audio') return 'MP3';
    return 'Uploaded video';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'club_id': clubId,
        'name': name,
        'url': url,
        'media_kind': mediaKind,
        'source_type': sourceType,
        if (createdBy != null) 'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  factory MediaAsset.fromMap(Map<String, dynamic> map) {
    return MediaAsset(
      id: map['id'] as String? ?? '',
      clubId: map['club_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled media',
      url: map['url'] as String? ?? '',
      mediaKind: map['media_kind'] as String? ?? 'video',
      sourceType: map['source_type'] as String? ?? 'video',
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  MediaAsset copyWith({
    String? name,
    String? url,
    String? mediaKind,
    String? sourceType,
  }) {
    return MediaAsset(
      id: id,
      clubId: clubId,
      name: name ?? this.name,
      url: url ?? this.url,
      mediaKind: mediaKind ?? this.mediaKind,
      sourceType: sourceType ?? this.sourceType,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
