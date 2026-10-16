import 'package:flutter/foundation.dart';

import '../Controller/order_controller.dart';
import '../Model/food.dart';
import '../Model/order_item.dart';
import '../Services/hive_cart_service.dart';

/// Provider layer: exposes cart state via [ChangeNotifier] and syncs
/// changes to Hive after each mutation.
class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderController? controller})
      : _controller = controller ?? OrderController();

  final OrderController _controller;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<OrderItem> get items => _controller.items;
  bool get isEmpty => _controller.isEmpty;
  int get totalQuantity => _controller.totalQuantity;
  double get totalPrice => _controller.totalPrice;

  /// Restores the cart from Hive. Call once after Provider is created.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final saved = await HiveCartService.loadCart();
      _controller.loadItems(saved);
    } catch (error) {
      _errorMessage = 'Could not load saved cart. Starting fresh.';
      debugPrint('OrderProvider.initialize: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(
    Food food, {
    int quantity = 1,
    String? selectedEdition,
    String? note,
  }) async {
    final ok = _controller.addItem(
      food,
      quantity: quantity,
      selectedEdition: selectedEdition,
      note: note,
    );
    if (!ok) return;
    await _persistAndNotify();
  }

  Future<void> increaseQuantity(int index) async {
    if (!_controller.increaseQuantity(index)) return;
    await _persistAndNotify();
  }

  Future<void> decreaseQuantity(int index) async {
    if (!_controller.decreaseQuantity(index)) return;
    await _persistAndNotify();
  }

  Future<void> setQuantity(int index, int quantity) async {
    if (!_controller.setQuantity(index, quantity)) return;
    await _persistAndNotify();
  }

  Future<void> removeItem(int index) async {
    if (!_controller.removeItem(index)) return;
    await _persistAndNotify();
  }

  Future<void> clearCart() async {
    _controller.clearCart();
    final cleared = await HiveCartService.clearCart();
    if (!cleared) {
      _errorMessage = 'Cart cleared in memory, but local save failed.';
    } else {
      _errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> _persistAndNotify() async {
    final saved = await HiveCartService.saveCart(_controller.items);
    if (!saved) {
      _errorMessage = 'Could not save cart to local storage.';
    } else {
      _errorMessage = null;
    }
    notifyListeners();
  }
}
