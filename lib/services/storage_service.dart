import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Profil Fotoğrafı Yükleme
  // Geriye yüklenen resmin internet adresini (URL) döndürür.
  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    try {
      // Dosya yolu: profile_images/KULLANICI_ID.jpg
      final ref = _storage.ref().child('profile_images/$uid.jpg');

      // Yükleme işlemi
      await ref.putFile(imageFile);

      // Yüklenen dosyanın linkini al
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("Resim yükleme hatası: $e");
      return null;
    }
  }
}
