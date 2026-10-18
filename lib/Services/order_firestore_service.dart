import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../Model/placed_order.dart';

/// Cloud Firestore CRUD for the `orders` collection.
class OrderFirestoreService {
  OrderFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'orders';

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(collectionName);

  Future<PlacedOrder> createOrder(PlacedOrder order) async {
    try {
      final ref = order.id.isEmpty ? _orders.doc() : _orders.doc(order.id);
      final toSave = PlacedOrder(
        id: ref.id,
        uid: order.uid,
        userEmail: order.userEmail,
        fullName: order.fullName,
        phone: order.phone,
        address: order.address,
        totalPrice: order.totalPrice,
        totalQuantity: order.totalQuantity,
        paymentMethod: order.paymentMethod,
        items: order.items,
        status: order.status,
        createdAt: order.createdAt ?? DateTime.now(),
      );
      await ref.set(toSave.toMap());
      return toSave;
    } catch (error, stackTrace) {
      debugPrint('OrderFirestoreService.createOrder: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw Exception(messageFromError(error));
    }
  }

  Future<List<PlacedOrder>> getOrdersForUser(String uid) async {
    try {
      final snap = await _orders
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(PlacedOrder.fromDoc).toList();
    } catch (error, stackTrace) {
      debugPrint('OrderFirestoreService.getOrdersForUser: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Fallback without orderBy if composite index is missing.
      try {
        final snap = await _orders.where('uid', isEqualTo: uid).get();
        final orders = snap.docs.map(PlacedOrder.fromDoc).toList()
          ..sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
        return orders;
      } catch (fallbackError) {
        throw Exception(messageFromError(fallbackError));
      }
    }
  }

  Stream<List<PlacedOrder>> watchOrdersForUser(String uid) {
    return _orders.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final orders = snap.docs.map(PlacedOrder.fromDoc).toList()
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
      return orders;
    });
  }

  static String messageFromError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission denied. Check Firestore rules for orders.';
        case 'unavailable':
          return 'Firestore is temporarily unavailable.';
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
