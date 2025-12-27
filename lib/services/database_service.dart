import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobil_prog_proje/models/goal_model.dart';
import 'package:mobil_prog_proje/models/session_model.dart';
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

  Future<void> saveSession(SessionModel session) async {
    final batch = _firestore.batch();

    // 1. Oturumu 'sessions' koleksiyonuna ekle
    final sessionRef = _firestore.collection('sessions').doc(session.id);
    batch.set(sessionRef, session.toMap());

    // 2. İlgili hedefin 'currentMinutes' değerini artır
    final goalRef = _firestore.collection('goals').doc(session.goalId);
    batch.update(goalRef, {
      'currentMinutes': FieldValue.increment(session.durationMinutes),
    });

    await batch.commit();
  }

  Stream<List<SessionModel>> getTodaySessions(String userId) {
    final now = DateTime.now();
    // Bugünün başlangıcı (Gece 00:00)
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return SessionModel.fromMap(doc.data());
          }).toList();
        });
  }
}
