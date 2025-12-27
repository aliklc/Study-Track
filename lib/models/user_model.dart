class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl; // YENİ EKLENDİ

  UserModel({required this.uid, this.email, this.displayName, this.photoUrl});

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'], // YENİ
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl, // YENİ
    };
  }
}
