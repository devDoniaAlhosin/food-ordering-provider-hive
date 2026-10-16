import 'package:hive/hive.dart';

import 'food.dart';

/// A line item in the shopping cart.
///
/// [selectedEdition] preserves the customization chosen when the item
/// was added (e.g. Medium). Items with the same food but different
/// editions are treated as separate cart lines.
class OrderItem {
  OrderItem({
    required this.food,
    this.quantity = 1,
    this.selectedEdition,
    this.note,
  }) : assert(quantity > 0, 'Quantity must be greater than zero');

  final Food food;
  int quantity;
  final String? selectedEdition;

  /// Optional special instructions entered via [TextFormField].
  final String? note;

  double get lineTotal => food.price * quantity;

  /// Unique key for matching cart lines (food + edition + note).
  String get cartKey =>
      '${food.id}::${selectedEdition ?? ''}::${note ?? ''}';

  OrderItem copyWith({
    Food? food,
    int? quantity,
    String? selectedEdition,
    String? note,
  }) {
    return OrderItem(
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
      selectedEdition: selectedEdition ?? this.selectedEdition,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'food': food.toMap(),
      'quantity': quantity,
      'selectedEdition': selectedEdition,
      'note': note,
    };
  }

  factory OrderItem.fromMap(Map<dynamic, dynamic> map) {
    return OrderItem(
      food: Food.fromMap(map['food'] as Map<dynamic, dynamic>),
      quantity: map['quantity'] as int,
      selectedEdition: map['selectedEdition'] as String?,
      note: map['note'] as String?,
    );
  }
}

/// Hive [TypeAdapter] for [OrderItem] (typeId: 1).
class OrderItemAdapter extends TypeAdapter<OrderItem> {
  @override
  final int typeId = 1;

  @override
  OrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderItem(
      food: fields[0] as Food,
      quantity: fields[1] as int,
      selectedEdition: fields[2] as String?,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.food)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.selectedEdition)
      ..writeByte(3)
      ..write(obj.note);
  }
}
