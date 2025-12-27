class UserModel {
  final String uid;
  final String? email;
  final String? displayName;

  UserModel({required this.uid, this.email, this.displayName});

  // Firebase verisini kendi modelimize çeviren fonksiyon
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'],
      displayName: data['displayName'],
    );
  }

  // Modelimizi Firebase'e gönderirken kullanan fonksiyon
  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'displayName': displayName};
  }
}
