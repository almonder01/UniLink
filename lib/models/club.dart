import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String logoColor; // 8-char hex, e.g. "FF6366F1"
  final String? logoImageBase64;
  final bool showLogoBackground;
  final String? imageBase64;
  final List<String> galleryBase64List;
  final String? backgroundVideoUrl;
  final String backgroundVideoType;
  final bool backgroundVideoAutoOpen;
  final String? backgroundMusicUrl;
  final String backgroundMusicType;
  final bool backgroundMusicAutoPlay;
  final String? featureTitle;
  final String? featureDescription;
  final String? featureCodeSnippet;
  final String? managerId;
  final String? managerName;
  final int memberCount;

  const ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.logoColor,
    this.logoImageBase64,
    this.showLogoBackground = true,
    this.imageBase64,
    this.galleryBase64List = const [],
    this.backgroundVideoUrl,
    this.backgroundVideoType = 'youtube',
    this.backgroundVideoAutoOpen = false,
    this.backgroundMusicUrl,
    this.backgroundMusicType = 'audio',
    this.backgroundMusicAutoPlay = true,
    this.featureTitle,
    this.featureDescription,
    this.featureCodeSnippet,
    this.managerId,
    this.managerName,
    required this.memberCount,
  });

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: d['category'] as String? ?? '',
      logoColor: d['logo_color'] as String? ?? 'FF6366F1',
      logoImageBase64: d['logo_image_base64'] as String?,
      showLogoBackground: d['show_logo_background'] as bool? ?? true,
      imageBase64: d['image_base64'] as String?,
      galleryBase64List:
          List<String>.from(d['gallery_base64_list'] ?? const []),
      backgroundVideoUrl: d['background_video_url'] as String?,
      backgroundVideoType: d['background_video_type'] as String? ?? 'youtube',
      backgroundVideoAutoOpen:
          d['background_video_auto_open'] as bool? ?? false,
      backgroundMusicUrl: d['background_music_url'] as String?,
      backgroundMusicType: d['background_music_type'] as String? ?? 'audio',
      backgroundMusicAutoPlay:
          d['background_music_auto_play'] as bool? ?? true,
      featureTitle: d['feature_title'] as String?,
      featureDescription: d['feature_description'] as String?,
      featureCodeSnippet: d['feature_code_snippet'] as String?,
      managerId: d['manager_id'] as String?,
      managerName: d['manager_name'] as String?,
      memberCount: (d['member_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'category': category,
        'logo_color': logoColor,
        if (logoImageBase64 != null) 'logo_image_base64': logoImageBase64,
        'show_logo_background': showLogoBackground,
        if (imageBase64 != null) 'image_base64': imageBase64,
        'gallery_base64_list': galleryBase64List,
        'background_video_url': backgroundVideoUrl?.trim() ?? '',
        'background_video_type': backgroundVideoType,
        'background_video_auto_open': backgroundVideoAutoOpen,
        'background_music_url': backgroundMusicUrl?.trim() ?? '',
        'background_music_type': backgroundMusicType,
        'background_music_auto_play': backgroundMusicAutoPlay,
        'feature_title': featureTitle?.trim() ?? '',
        'feature_description': featureDescription?.trim() ?? '',
        'feature_code_snippet': featureCodeSnippet?.trim() ?? '',
        if (managerId != null) 'manager_id': managerId,
        if (managerName != null) 'manager_name': managerName,
        'member_count': memberCount,
      };

  ClubModel copyWith({
    String? name,
    String? description,
    String? logoColor,
    String? logoImageBase64,
    bool? showLogoBackground,
    String? imageBase64,
    List<String>? galleryBase64List,
    String? backgroundVideoUrl,
    String? backgroundVideoType,
    bool? backgroundVideoAutoOpen,
    String? backgroundMusicUrl,
    String? backgroundMusicType,
    bool? backgroundMusicAutoPlay,
    String? featureTitle,
    String? featureDescription,
    String? featureCodeSnippet,
    String? managerId,
    String? managerName,
  }) {
    return ClubModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category,
      logoColor: logoColor ?? this.logoColor,
      logoImageBase64: logoImageBase64 ?? this.logoImageBase64,
      showLogoBackground: showLogoBackground ?? this.showLogoBackground,
      imageBase64: imageBase64 ?? this.imageBase64,
      galleryBase64List: galleryBase64List ?? this.galleryBase64List,
      backgroundVideoUrl: backgroundVideoUrl ?? this.backgroundVideoUrl,
      backgroundVideoType: backgroundVideoType ?? this.backgroundVideoType,
      backgroundVideoAutoOpen:
          backgroundVideoAutoOpen ?? this.backgroundVideoAutoOpen,
      backgroundMusicUrl: backgroundMusicUrl ?? this.backgroundMusicUrl,
      backgroundMusicType: backgroundMusicType ?? this.backgroundMusicType,
      backgroundMusicAutoPlay:
          backgroundMusicAutoPlay ?? this.backgroundMusicAutoPlay,
      featureTitle: featureTitle ?? this.featureTitle,
      featureDescription: featureDescription ?? this.featureDescription,
      featureCodeSnippet: featureCodeSnippet ?? this.featureCodeSnippet,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      memberCount: memberCount,
    );
  }
}
