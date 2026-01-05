import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobil_prog_proje/models/goal_model.dart';
import 'package:mobil_prog_proje/models/post_model.dart';
import 'package:mobil_prog_proje/models/session_model.dart';
import '../models/user_model.dart';
import 'package:mobil_prog_proje/models/comment_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print("Kullanıcı kaydetme hatası: $e");
      rethrow;
    }
  }

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

  Future<void> deleteGoal(String goalId) async {
    await _firestore.collection('goals').doc(goalId).delete();
  }

  Future<void> saveSession(SessionModel session) async {
    final batch = _firestore.batch();

    final sessionRef = _firestore.collection('sessions').doc(session.id);
    batch.set(sessionRef, session.toMap());

    final goalRef = _firestore.collection('goals').doc(session.goalId);
    batch.update(goalRef, {
      'currentMinutes': FieldValue.increment(session.durationMinutes),
    });

    await batch.commit();
  }

  Stream<List<SessionModel>> getTodaySessions(String userId) {
    final now = DateTime.now();
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

  Future<List<SessionModel>> getLast7DaysSessions(String userId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final startOfSevenDaysAgo = DateTime(
      sevenDaysAgo.year,
      sevenDaysAgo.month,
      sevenDaysAgo.day,
    );

    final querySnapshot = await _firestore
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where(
          'date',
          isGreaterThanOrEqualTo: startOfSevenDaysAgo.toIso8601String(),
        )
        .get();

    return querySnapshot.docs
        .map((doc) => SessionModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> addPost(PostModel post) async {
    await _firestore.collection('posts').doc(post.id).set(post.toMap());
  }

  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PostModel.fromMap(doc.data());
          }).toList();
        });
  }

  // --- POST BEĞENİ İŞLEMLERİ ---
  Future<void> togglePostLike(
    String postId,
    String userId,
    List<String> likes,
  ) async {
    final docRef = _firestore.collection('posts').doc(postId);

    if (likes.contains(userId)) {
      // Zaten beğenmişse kaldır
      await docRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      // Beğenmemişse ekle
      await docRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // --- YORUM İŞLEMLERİ ---

  // Yorum Ekleme (Sub-collection olarak yapıyoruz: posts -> comments)
  Future<void> addComment(CommentModel comment) async {
    await _firestore
        .collection('posts')
        .doc(comment.postId)
        .collection('comments') // Postun altında 'comments' koleksiyonu
        .doc(comment.id)
        .set(comment.toMap());
  }

  // Yorumları Getirme
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false) // Eskiler üstte
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CommentModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Yorum Beğeni İşlemleri
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
    List<String> likes,
  ) async {
    final docRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    if (likes.contains(userId)) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }
}
