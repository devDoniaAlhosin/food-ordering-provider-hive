import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../Model/app_user.dart';
import '../Services/auth_service.dart';
import '../Services/user_firestore_service.dart';

/// Exposes Firebase auth state to the UI via [ChangeNotifier].
class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({
    AuthService? authService,
    UserFirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService(),
        _firestore = firestoreService ?? UserFirestoreService() {
    _startListening();
  }

  final AuthService _authService;
  final UserFirestoreService _firestore;

  StreamSubscription<User?>? _subscription;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  bool _busy = false;
  bool get isBusy => _busy;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Optional callback when auth user changes (used to sync UserProvider).
  void Function(User? user)? onAuthUserChanged;

  void _startListening() {
    try {
      _user = _authService.currentUser;
      _subscription = _authService.authStateChanges().listen(
        (user) {
          _user = user;
          onAuthUserChanged?.call(user);
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('AppAuthProvider stream error: $error');
          debugPrintStack(stackTrace: stackTrace);
          _errorMessage = AuthService.messageFromError(error);
          notifyListeners();
        },
      );
    } catch (error, stackTrace) {
      debugPrint('AppAuthProvider listen failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = AuthService.messageFromError(error);
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
    String phone = '',
    String address = '',
  }) async {
    return _run(() async {
      final credential = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _user = _authService.currentUser;
      final uid = credential.user?.uid ?? _user?.uid;
      if (uid == null) {
        throw Exception('Registration succeeded but user id is missing.');
      }
      final appUser = AppUser(
        uid: uid,
        email: email.trim(),
        fullName: (displayName ?? '').trim().isNotEmpty
            ? displayName!.trim()
            : email.trim().split('@').first,
        phone: phone.trim(),
        address: address.trim(),
        role: UserRole.user,
        createdAt: DateTime.now(),
      );
      await _firestore.createUser(appUser);
    });
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      await _authService.login(email: email, password: password);
      _user = _authService.currentUser;
    });
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (error) {
      debugPrint('AppAuthProvider logout: $error');
    }
    _user = null;
    onAuthUserChanged?.call(null);
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = AuthService.messageFromError(error);
      // Prefer Firestore message when thrown as Exception from service
      if (error is Exception) {
        final text = error.toString();
        if (text.contains('permission') || text.contains('Firestore')) {
          _errorMessage = UserFirestoreService.messageFromError(error);
        }
      }
      debugPrint('AppAuthProvider error: $error');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
