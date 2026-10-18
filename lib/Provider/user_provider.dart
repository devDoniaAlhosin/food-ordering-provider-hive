import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../Model/app_user.dart';
import '../Services/auth_service.dart';
import '../Services/user_firestore_service.dart';

/// Firestore users state: current profile + full users list CRUD.
class UserProvider extends ChangeNotifier {
  UserProvider({
    UserFirestoreService? firestoreService,
    AuthService? authService,
  })  : _firestore = firestoreService ?? UserFirestoreService(),
        _authService = authService ?? AuthService();

  final UserFirestoreService _firestore;
  final AuthService _authService;

  StreamSubscription<List<AppUser>>? _usersSub;

  AppUser? _currentProfile;
  AppUser? get currentProfile => _currentProfile;
  bool get isAdmin => _currentProfile?.isAdmin ?? false;

  List<AppUser> _users = [];
  List<AppUser> get users => List.unmodifiable(_users);

  bool _loadingProfile = false;
  bool get isLoadingProfile => _loadingProfile;

  bool _loadingUsers = false;
  bool get isLoadingUsers => _loadingUsers;

  bool _busy = false;
  bool get isBusy => _busy;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser(String uid) async {
    _loadingProfile = true;
    _errorMessage = null;
    notifyListeners();
    try {
      var profile = await _firestore.getUser(uid);
      // Backfill for Auth users created before Firestore sync existed.
      if (profile == null) {
        final authUser = _authService.currentUser;
        if (authUser != null && authUser.uid == uid) {
          profile = AppUser(
            uid: uid,
            email: authUser.email ?? '',
            fullName: authUser.displayName?.trim().isNotEmpty == true
                ? authUser.displayName!.trim()
                : (authUser.email?.split('@').first ?? 'User'),
            role: UserRole.user,
          );
          await _firestore.createUser(profile);
        }
      }
      _currentProfile = profile;
    } catch (error) {
      _errorMessage = UserFirestoreService.messageFromError(error);
      debugPrint('UserProvider.loadCurrentUser: $error');
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  void clearCurrentProfile() {
    _currentProfile = null;
    notifyListeners();
  }

  void startWatchingUsers() {
    if (!isAdmin) {
      _errorMessage = 'Only admins can manage users.';
      _users = [];
      notifyListeners();
      return;
    }
    _loadingUsers = true;
    _errorMessage = null;
    notifyListeners();
    _usersSub?.cancel();
    _usersSub = _firestore.watchUsers().listen(
      (list) {
        _users = list;
        _loadingUsers = false;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = UserFirestoreService.messageFromError(error);
        _loadingUsers = false;
        notifyListeners();
      },
    );
  }

  Future<void> refreshUsers() async {
    if (!isAdmin) {
      _errorMessage = 'Only admins can manage users.';
      notifyListeners();
      return;
    }
    _loadingUsers = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _users = await _firestore.getAllUsers();
    } catch (error) {
      _errorMessage = UserFirestoreService.messageFromError(error);
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> createProfileForAuthUser({
    required String uid,
    required String email,
    required String fullName,
    String phone = '',
    String address = '',
    UserRole role = UserRole.user,
  }) async {
    return _run(() async {
      final user = AppUser(
        uid: uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        address: address.trim(),
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore.createUser(user);
      _currentProfile = user;
    });
  }

  Future<bool> updateProfile({
    required String fullName,
    String phone = '',
    String address = '',
  }) async {
    final existing = _currentProfile;
    if (existing == null) {
      _errorMessage = 'No profile loaded.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      final updated = existing.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
        address: address.trim(),
        updatedAt: DateTime.now(),
      );
      await _firestore.updateUser(updated);
      _currentProfile = updated;
      // Keep Auth display name in sync
      final authUser = _authService.currentUser;
      if (authUser != null && authUser.uid == updated.uid) {
        await authUser.updateDisplayName(updated.fullName);
      }
    });
  }

  /// Creates Auth account + Firestore doc (signs in as the new user).
  /// Admin-only. New accounts default to [UserRole.user] unless [role] is set.
  Future<bool> createUserWithAuth({
    required String email,
    required String password,
    required String fullName,
    String phone = '',
    String address = '',
    UserRole role = UserRole.user,
  }) async {
    if (!isAdmin) {
      _errorMessage = 'Only admins can create users.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      final credential = await _authService.register(
        email: email,
        password: password,
        displayName: fullName,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('Could not create auth user.');
      }
      final user = AppUser(
        uid: uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        address: address.trim(),
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore.createUser(user);
      _currentProfile = user;
    });
  }

  Future<bool> updateUser(AppUser user) async {
    if (!isAdmin && _currentProfile?.uid != user.uid) {
      _errorMessage = 'You can only update your own account.';
      notifyListeners();
      return false;
    }
    // Non-admins cannot change their own role.
    final safeUser = (!isAdmin && _currentProfile?.uid == user.uid)
        ? user.copyWith(role: _currentProfile!.role)
        : user;
    return _run(() async {
      final updated = safeUser.copyWith(updatedAt: DateTime.now());
      await _firestore.updateUser(updated);
      if (_currentProfile?.uid == updated.uid) {
        _currentProfile = updated;
      }
      final index = _users.indexWhere((u) => u.uid == updated.uid);
      if (index >= 0) {
        _users = [..._users]..[index] = updated;
      }
    });
  }

  /// Admin deletes any user, or a user deletes their own account.
  Future<bool> deleteUser(String uid, {String? password}) async {
    final isSelf = _currentProfile?.uid == uid;
    if (!isAdmin && !isSelf) {
      _errorMessage = 'You can only delete your own account.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      if (isSelf) {
        final email = _currentProfile?.email ??
            FirebaseAuth.instance.currentUser?.email;
        if (email == null || email.isEmpty) {
          throw Exception('Missing email for account deletion.');
        }
        // Firebase requires a recent login before deleting Auth users.
        if (password != null && password.isNotEmpty) {
          await _authService.reauthenticate(
            email: email,
            password: password,
          );
        }
        await _firestore.deleteUser(uid);
        _users = _users.where((u) => u.uid != uid).toList();
        await _authService.deleteCurrentAccount();
        _currentProfile = null;
        return;
      }

      await _firestore.deleteUser(uid);
      _users = _users.where((u) => u.uid != uid).toList();
    });
  }

  /// Current user deletes their own Auth + Firestore account.
  Future<bool> deleteMyAccount({required String password}) async {
    final uid = _currentProfile?.uid;
    if (uid == null) {
      _errorMessage = 'No profile loaded.';
      notifyListeners();
      return false;
    }
    return deleteUser(uid, password: password);
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      if (error is FirebaseAuthException) {
        _errorMessage = AuthService.messageFromError(error);
      } else {
        _errorMessage = UserFirestoreService.messageFromError(error);
      }
      debugPrint('UserProvider error: $error');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
