import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobil_prog_proje/models/goal_model.dart';
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

  Future<void> addGoal(GoalModel goal) async {
    try {
      await _firestore.collection('goals').doc(goal.id).set(goal.toMap());
    } catch (e) {
      print("Hedef ekleme hatası: $e");
      rethrow;
    }
  }

  // KULLANICININ HEDEFLERİNİ GETİRME (Stream olarak - Canlı veri)
  Stream<List<GoalModel>> getUserGoals(String userId) {
    return _firestore
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return GoalModel.fromMap(doc.data());
          }).toList();
        });
  }

  // HEDEF SİLME (Opsiyonel ama gerekli olur)
  Future<void> deleteGoal(String goalId) async {
    await _firestore.collection('goals').doc(goalId).delete();
  }
}
