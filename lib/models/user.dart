class UserModel {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final String role; // student | admin | manager
  final String? major;
  final String? photoUrl;
  final String? managedClubId;
  final String? gender;

  const UserModel({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.role,
    this.major,
    this.photoUrl,
    this.managedClubId,
    this.gender,
  });

  static UserModel fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        studentId: m['student_id'] as String? ?? '',
        email: m['email'] as String? ?? '',
        role: m['role'] as String? ?? 'student',
        major: m['major'] as String?,
        gender: m['gender'] as String?,
        managedClubId: m['managed_club_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'student_id': studentId,
        'email': email,
        'role': role,
        if (major != null) 'major': major,
        if (gender != null) 'gender': gender,
        if (managedClubId != null) 'managed_club_id': managedClubId,
      };

  UserModel copyWith({String? name, String? major, String? photoUrl, String? gender}) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      studentId: studentId,
      email: email,
      role: role,
      major: major ?? this.major,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      managedClubId: managedClubId,
    );
  }
}
