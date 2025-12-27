import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Anlık Kullanıcı Durumu
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Yükleniyor bilgisini güncellemek için
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // KAYIT OL (Sign Up)
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return null; // Hata yok, başarıyla kayıt olundu.
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message; // Hata mesajını döndür.
    }
  }

  // GİRİŞ YAP (Sign In)
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message;
    }
  }

  // ÇIKIŞ YAP (Sign Out)
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ŞİFRE SIFIRLAMA
  Future<String?> resetPassword({required String email}) async {
    _setLoading(true);
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message;
    }
  }
}
