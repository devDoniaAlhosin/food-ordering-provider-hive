import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../Model/app_user.dart';

/// Cloud Firestore CRUD for the `users` collection.
class UserFirestoreService {
  UserFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'users';

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(collectionName);

  Future<void> createUser(AppUser user) async {
    try {
      await _users.doc(user.uid).set(user.toMap());
    } catch (error, stackTrace) {
      debugPrint('UserFirestoreService.createUser: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(messageFromError(error));
    }
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final snap = await _users.doc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromDoc(snap);
    } catch (error, stackTrace) {
      debugPrint('UserFirestoreService.getUser: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(messageFromError(error));
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      final snap = await _users.orderBy('fullName').get();
      return snap.docs.map(AppUser.fromDoc).toList();
    } catch (error, stackTrace) {
      debugPrint('UserFirestoreService.getAllUsers: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Fallback without orderBy if index missing or empty field
      try {
        final snap = await _users.get();
        final users = snap.docs.map(AppUser.fromDoc).toList()
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );
        return users;
      } catch (fallbackError) {
        throw Exception(messageFromError(fallbackError));
      }
    }
  }

  Stream<List<AppUser>> watchUsers() {
    return _users.snapshots().map((snap) {
      final users = snap.docs.map(AppUser.fromDoc).toList()
        ..sort(
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      return users;
    });
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _users.doc(user.uid).update(user.toUpdateMap());
    } catch (error, stackTrace) {
      debugPrint('UserFirestoreService.updateUser: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(messageFromError(error));
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _users.doc(uid).delete();
    } catch (error, stackTrace) {
      debugPrint('UserFirestoreService.deleteUser: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(messageFromError(error));
    }
  }

  static String messageFromError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore permission denied. Check security rules.';
        case 'unavailable':
          return 'Firestore is temporarily unavailable.';
        case 'not-found':
          return 'User document was not found.';
        default:
          return error.message ?? 'Firestore error.';
      }
    }
    if (error is Exception) {
      final text = error.toString();
      if (text.startsWith('Exception: ')) {
        return text.substring('Exception: '.length);
      }
      return text;
    }
    return 'Firestore error.';
  }
}
