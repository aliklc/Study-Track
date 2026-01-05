class CommentModel {
  final String id;
  final String postId; // Hangi postun yorumu
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String message;
  final DateTime timestamp;
  final List<String> likes; // Yorumu beğenenler

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    required this.timestamp,
    required this.likes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'],
      postId: map['postId'],
      userId: map['userId'],
      userName: map['userName'] ?? 'İsimsiz',
      userPhotoUrl: map['userPhotoUrl'],
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
}
