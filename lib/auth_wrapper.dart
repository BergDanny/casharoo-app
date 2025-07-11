import 'package:casharoo_app/pages/login_page.dart';
import 'package:casharoo_app/pages/main_page.dart';
import 'package:casharoo_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading spinner while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FFFE),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6E5E)),
            ),
          );
        }

        // If user is logged in, show MainPage
        // AuthService will handle profile validation during sign-in
        if (snapshot.hasData && snapshot.data != null) {
          return const MainPage();
        }

        // If user is not logged in, show LoginPage
        return const LoginPage();
      },
    );
  }
}
