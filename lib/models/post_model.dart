class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl; // Yazarın profil resmi
  final String message;
  final String? postImageUrl; // Paylaşılan fotoğraf (varsa)
  final DateTime timestamp;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    this.postImageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'message': message,
      'postImageUrl': postImageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'] ?? 'İsimsiz',
      userPhotoUrl: map['userPhotoUrl'],
      message: map['message'] ?? '',
      postImageUrl: map['postImageUrl'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
