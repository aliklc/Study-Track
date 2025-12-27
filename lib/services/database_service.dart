import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı verisini kaydetme veya güncelleme
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
            user.toMap(),
            SetOptions(merge: true), // Varsa güncelle, yoksa oluştur
          );
    } catch (e) {
      print("Kullanıcı kaydetme hatası: $e");
      rethrow;
    }
  }

  // Kullanıcı verisini çekme
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      print("Kullanıcı getirme hatası: $e");
      return null;
    }
  }
}
