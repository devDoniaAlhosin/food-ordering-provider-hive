import '../Model/food.dart';
import '../Model/order_item.dart';

/// Business logic for the shopping cart (MVC Controller).
///
/// Keeps cart mutations and totals out of the UI. Does not notify
/// listeners — that responsibility belongs to [OrderProvider].
class OrderController {
  final List<OrderItem> _items = [];

  List<OrderItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// Replaces the in-memory cart (used when restoring from Hive).
  void loadItems(List<OrderItem> saved) {
    _items
      ..clear()
      ..addAll(
        saved.where((item) => item.quantity > 0).map(
              (item) => OrderItem(
                food: item.food,
                quantity: item.quantity,
                selectedEdition: item.selectedEdition,
              ),
            ),
      );
  }

  /// Adds [food] to the cart, merging with an existing line that shares
  /// the same food id and [selectedEdition].
  ///
  /// Returns `false` if [quantity] is invalid.
  bool addItem(Food food, {int quantity = 1, String? selectedEdition}) {
    if (quantity <= 0) return false;

    final edition = selectedEdition ??
        (food.editions.isNotEmpty ? food.editions.first : null);
    final key = '${food.id}::${edition ?? ''}';

    final index = _items.indexWhere((item) => item.cartKey == key);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(
        OrderItem(
          food: food,
          quantity: quantity,
          selectedEdition: edition,
        ),
      );
    }
    return true;
  }

  /// Increases quantity for the line at [index]. Returns `false` if invalid.
  bool increaseQuantity(int index) {
    if (!_isValidIndex(index)) return false;
    _items[index].quantity += 1;
    return true;
  }

  /// Decreases quantity; removes the line when quantity would drop below 1.
  bool decreaseQuantity(int index) {
    if (!_isValidIndex(index)) return false;
    if (_items[index].quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index].quantity -= 1;
    }
    return true;
  }

  /// Sets an absolute quantity. Removes the line when [quantity] is below 1.
  bool setQuantity(int index, int quantity) {
    if (!_isValidIndex(index)) return false;
    if (quantity < 1) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
    return true;
  }

  bool removeItem(int index) {
    if (!_isValidIndex(index)) return false;
    _items.removeAt(index);
    return true;
  }

  void clearCart() {
    _items.clear();
  }

  bool _isValidIndex(int index) => index >= 0 && index < _items.length;
}
