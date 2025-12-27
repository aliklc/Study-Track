import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  File? _selectedImage;
  String? _currentPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Kullanıcı verilerini Firestore'dan çekip ekrana basar
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final userModel = await _dbService.getUser(user.uid);
      if (userModel != null) {
        _nameController.text = userModel.displayName ?? "";
        _currentPhotoUrl = userModel.photoUrl;
      } else {
        // Firestore'da kayıt yoksa Auth'dan gelen e-postayı gösterelim
        _nameController.text = user.displayName ?? "";
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // Galeriden resim seçme
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Kaydetme İşlemi
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    String? photoUrl = _currentPhotoUrl;

    // Yeni resim seçildiyse yükle
    if (_selectedImage != null) {
      photoUrl = await _storageService.uploadProfileImage(
        user.uid,
        _selectedImage!,
      );
    }

    final updatedUser = UserModel(
      uid: user.uid,
      email: user.email,
      displayName: _nameController.text.trim(),
      photoUrl: photoUrl,
    );

    await _dbService.saveUser(updatedUser);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil güncellendi!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profilim")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profil Fotoğrafı Alanı
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_currentPhotoUrl != null
                                ? NetworkImage(_currentPhotoUrl!)
                                      as ImageProvider
                                : null),
                      child:
                          (_selectedImage == null && _currentPhotoUrl == null)
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Fotoğrafı değiştirmek için dokun",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // İsim Alanı
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Ad Soyad",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saveProfile,
                      child: const Text("Kaydet"),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Çıkış Yap Butonu
                  TextButton.icon(
                    onPressed: () {
                      context.read<AuthService>().signOut();
                      Navigator.pop(context); // Ekranı kapat
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      "Çıkış Yap",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
