import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService =
      StorageService(); // Storage servisini çağırdık

  File? _selectedImage;
  bool _isLoading = false;

  // Galeriden resim seçme fonksiyonu
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Kaydı Tamamlama Fonksiyonu
  Future<void> _completeRegistration() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen isminizi giriniz.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        String? photoUrl;

        // Eğer resim seçildiyse Storage'a yükle ve linkini al
        if (_selectedImage != null) {
          photoUrl = await _storageService.uploadProfileImage(
            user.uid,
            _selectedImage!,
          );
        }

        // Firestore'a kaydedilecek UserModel'i oluştur
        final newUser = UserModel(
          uid: user.uid,
          email: user.email,
          displayName: _nameController.text.trim(),
          photoUrl: photoUrl,
        );

        // DatabaseService'deki saveUser fonksiyonunu kullanarak kaydet
        await _dbService.saveUser(newUser);

        if (mounted) {
          // Her şey bittiğinde ana ekrana yönlendir ve geri dönüşü engelle
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      print("Hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Bir hata oluştu: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profili Tamamla")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    "Kaydınız oluşturuldu!\nLütfen profil bilgilerinizi tamamlayın.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Fotoğraf Seçme Alanı
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                Text(
                                  "Fotoğraf Ekle",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // İsim Girme Alanı
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Ad Soyad",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Kaydı Tamamla Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _completeRegistration,
                      child: const Text("Kaydı Tamamla"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
