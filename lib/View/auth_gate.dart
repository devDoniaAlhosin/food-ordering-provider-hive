import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/auth_provider.dart';
import '../Provider/orders_provider.dart';
import '../Provider/user_provider.dart';
import 'auth/welcome_screen.dart';
import 'main_shell.dart';

/// Shows [WelcomeScreen] until Firebase Auth reports a signed-in user.
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
    final orders = context.read<OrdersProvider>();

    void sync(user) {
      if (user == null) {
        users.clearCurrentProfile();
        orders.clear();
        MainShell.tabIndex.value = 0;
      } else {
        MainShell.tabIndex.value = 0; // Menu tab after login
        users.loadCurrentUser(user.uid);
        orders.startWatching(user.uid);
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
      return const MainShell();
    }
    return const WelcomeScreen();
  }
}
