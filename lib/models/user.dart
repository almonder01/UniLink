class UserModel {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final String role; // student | admin | manager
  final String? major;
  final String? photoUrl;
  final String? photoBase64;
  final String? coverImageBase64;
  final String coverColor;
  final String? managedClubId;
  final String? gender;
  final bool showInClubMembers;

  const UserModel({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.role,
    this.major,
    this.photoUrl,
    this.photoBase64,
    this.coverImageBase64,
    this.coverColor = 'FF6366F1',
    this.managedClubId,
    this.gender,
    this.showInClubMembers = true,
  });

  static UserModel fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        studentId: m['student_id'] as String? ?? '',
        email: m['email'] as String? ?? '',
        role: m['role'] as String? ?? 'student',
        major: m['major'] as String?,
        photoUrl: m['photo_url'] as String?,
        photoBase64: m['photo_base64'] as String?,
        coverImageBase64: m['cover_image_base64'] as String?,
        coverColor: m['cover_color'] as String? ?? 'FF6366F1',
        gender: m['gender'] as String?,
        managedClubId: m['managed_club_id'] as String?,
        showInClubMembers: m['show_in_club_members'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'student_id': studentId,
        'email': email,
        'role': role,
        if (major != null) 'major': major,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (photoBase64 != null) 'photo_base64': photoBase64,
        if (coverImageBase64 != null) 'cover_image_base64': coverImageBase64,
        'cover_color': coverColor,
        if (gender != null) 'gender': gender,
        'show_in_club_members': showInClubMembers,
        if (managedClubId != null) 'managed_club_id': managedClubId,
      };

  UserModel copyWith({
    String? name,
    String? major,
    String? photoUrl,
    String? photoBase64,
    String? coverImageBase64,
    String? coverColor,
    String? gender,
    bool? showInClubMembers,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      studentId: studentId,
      email: email,
      role: role,
      major: major ?? this.major,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
      coverColor: coverColor ?? this.coverColor,
      managedClubId: managedClubId,
      showInClubMembers: showInClubMembers ?? this.showInClubMembers,
    );
  }
}
