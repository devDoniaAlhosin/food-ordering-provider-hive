import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Model/food.dart';
import '../Model/order_item.dart';

/// Local persistence for cart items using Hive.
class HiveCartService {
  HiveCartService._();

  static const String boxName = 'cart_box';
  static const String cartKey = 'order_items';

  static bool _initialized = false;

  /// Initializes Hive, registers adapters, and opens the cart box.
  ///
  /// Safe to call once at app startup. Errors are logged and rethrown
  /// so the UI can show a fallback message.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(FoodAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(OrderItemAdapter());
      }

      await Hive.openBox<dynamic>(boxName);
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('HiveCartService.init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  /// Loads previously saved cart items. Returns an empty list on error.
  static Future<List<OrderItem>> loadCart() async {
    try {
      if (!_initialized) {
        await init();
      }
      final raw = _box.get(cartKey);
      if (raw == null) return [];

      if (raw is List) {
        return raw
            .whereType<OrderItem>()
            .where((item) => item.quantity > 0)
            .map(
              (item) => OrderItem(
                food: item.food,
                quantity: item.quantity,
                selectedEdition: item.selectedEdition,
                note: item.note,
              ),
            )
            .toList();
      }
      return [];
    } catch (error, stackTrace) {
      debugPrint('HiveCartService.loadCart failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  /// Persists the current cart. Returns `false` if saving fails.
  static Future<bool> saveCart(List<OrderItem> items) async {
    try {
      if (!_initialized) {
        await init();
      }
      await _box.put(
        cartKey,
        items
            .map(
              (item) => OrderItem(
                food: item.food,
                quantity: item.quantity,
                selectedEdition: item.selectedEdition,
                note: item.note,
              ),
            )
            .toList(),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('HiveCartService.saveCart failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Clears persisted cart data.
  static Future<bool> clearCart() async {
    try {
      if (!_initialized) {
        await init();
      }
      await _box.delete(cartKey);
      return true;
    } catch (error, stackTrace) {
      debugPrint('HiveCartService.clearCart failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
