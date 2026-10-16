import 'package:hive/hive.dart';

/// Catalog item shown on the food menu.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.description = '',
    this.editions = const [],
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String description;

  /// Optional size / edition choices (e.g. Small, Medium, Large).
  final List<String> editions;

  Food copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? imageUrl,
    String? description,
    List<String>? editions,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      editions: editions ?? this.editions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'editions': editions,
    };
  }

  factory Food.fromMap(Map<dynamic, dynamic> map) {
    return Food(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      description: (map['description'] as String?) ?? '',
      editions: (map['editions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Food &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Hive [TypeAdapter] for [Food] (typeId: 0).
class FoodAdapter extends TypeAdapter<Food> {
  @override
  final int typeId = 0;

  @override
  Food read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Food(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      price: fields[3] as double,
      imageUrl: fields[4] as String,
      description: (fields[5] as String?) ?? '',
      editions: (fields[6] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, Food obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.editions);
  }
}
