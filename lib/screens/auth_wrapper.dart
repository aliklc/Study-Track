import 'package:flutter/material.dart';
import 'package:mobil_prog_proje/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Durum yükleniyorsa bekleme ekranı göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Kullanıcı giriş yapmışsa Dashboard (şimdilik geçici ekran)
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("StudyTrack"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Hoşgeldin, ${snapshot.data?.displayName}"),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }

        // Kullanıcı yoksa Login ekranına git
        return const LoginScreen();
      },
    );
  }
}
