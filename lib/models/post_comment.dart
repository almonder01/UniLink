class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoBase64;
  final String? userGender;
  final String text;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoBase64,
    this.userGender,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'userName': userName,
        if (userPhotoBase64 != null) 'userPhotoBase64': userPhotoBase64,
        if (userGender != null) 'userGender': userGender,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PostComment.fromMap(Map<String, dynamic> map) => PostComment(
        id: map['id'] as String? ?? '',
        postId: map['postId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? 'Student',
        userPhotoBase64: map['userPhotoBase64'] as String?,
        userGender: map['userGender'] as String?,
        text: map['text'] as String? ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
