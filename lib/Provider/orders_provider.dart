import 'dart:async';

import 'package:flutter/foundation.dart';

import '../Model/order_item.dart';
import '../Model/placed_order.dart';
import '../Services/order_firestore_service.dart';

/// Current user's placed orders from Firestore.
class OrdersProvider extends ChangeNotifier {
  OrdersProvider({OrderFirestoreService? firestoreService})
      : _firestore = firestoreService ?? OrderFirestoreService();

  final OrderFirestoreService _firestore;
  StreamSubscription<List<PlacedOrder>>? _sub;

  List<PlacedOrder> _orders = [];
  List<PlacedOrder> get orders => List.unmodifiable(_orders);

  bool _loading = false;
  bool get isLoading => _loading;

  bool _busy = false;
  bool get isBusy => _busy;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _uid;

  void startWatching(String uid) {
    if (_uid == uid && _sub != null) return;
    _uid = uid;
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    _sub?.cancel();
    _sub = _firestore.watchOrdersForUser(uid).listen(
      (list) {
        _orders = list;
        _loading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = OrderFirestoreService.messageFromError(error);
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _orders = await _firestore.getOrdersForUser(uid);
    } catch (error) {
      _errorMessage = OrderFirestoreService.messageFromError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    _orders = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Saves a new order for the signed-in user and returns it.
  Future<PlacedOrder?> placeOrder({
    required String uid,
    required String userEmail,
    required String fullName,
    required String phone,
    required String address,
    required double totalPrice,
    required int totalQuantity,
    required List<OrderItem> cartItems,
  }) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final draft = PlacedOrder.fromCheckout(
        id: '',
        uid: uid,
        userEmail: userEmail,
        fullName: fullName,
        phone: phone,
        address: address,
        totalPrice: totalPrice,
        totalQuantity: totalQuantity,
        cartItems: cartItems,
      );
      final saved = await _firestore.createOrder(draft);
      // Optimistic insert if stream is slow
      if (!_orders.any((o) => o.id == saved.id)) {
        _orders = [saved, ..._orders];
      }
      return saved;
    } catch (error) {
      _errorMessage = OrderFirestoreService.messageFromError(error);
      debugPrint('OrdersProvider.placeOrder: $error');
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
