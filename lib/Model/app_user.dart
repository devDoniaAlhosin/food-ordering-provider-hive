import 'package:cloud_firestore/cloud_firestore.dart';

/// App roles stored on the Firestore user document.
enum UserRole { user, admin }

extension UserRoleX on UserRole {
  String get firestoreValue => name;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

/// App user profile stored in Firestore `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.address = '',
    this.role = UserRole.user,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String address;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phone,
    String? address,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'role': role.firestoreValue,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Map used for updates (keeps existing createdAt).
  Map<String, dynamic> toUpdateMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'role': role.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? readTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return AppUser(
      uid: (map['uid'] as String?) ?? docId ?? '',
      email: (map['email'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      role: UserRoleX.fromString(map['role'] as String?),
      createdAt: readTime(map['createdAt']),
      updatedAt: readTime(map['updatedAt']),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser.fromMap(data, docId: doc.id);
  }
}
