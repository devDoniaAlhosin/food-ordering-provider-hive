import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/auth_provider.dart';
import 'auth/login_screen.dart';
import 'food_menu_screen.dart';

/// Shows [LoginScreen] until Firebase Auth reports a signed-in user.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    if (auth.isLoggedIn) {
      return const FoodMenuScreen();
    }
    return const LoginScreen();
  }
}
