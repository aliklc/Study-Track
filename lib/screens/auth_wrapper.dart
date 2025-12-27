import 'package:flutter/material.dart';
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
            appBar: AppBar(title: const Text("Dashboard")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Hoşgeldin, ${snapshot.data?.email}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthService>().signOut();
                    },
                    child: const Text("Çıkış Yap"),
                  ),
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
