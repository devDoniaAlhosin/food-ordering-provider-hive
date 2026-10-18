import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/auth_provider.dart';
import '../Provider/user_provider.dart';
import 'auth/login_screen.dart';
import 'food_menu_screen.dart';

/// Shows [LoginScreen] until Firebase Auth reports a signed-in user.
/// Also syncs the Firestore profile when auth state changes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindAuthSync());
  }

  void _bindAuthSync() {
    if (!mounted) return;
    final auth = context.read<AppAuthProvider>();
    final users = context.read<UserProvider>();

    void sync(user) {
      if (user == null) {
        users.clearCurrentProfile();
      } else {
        users.loadCurrentUser(user.uid);
      }
    }

    auth.onAuthUserChanged = sync;
    // Initial sync for already-signed-in session
    sync(auth.user);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    if (auth.isLoggedIn) {
      return const FoodMenuScreen();
    }
    return const LoginScreen();
  }
}
