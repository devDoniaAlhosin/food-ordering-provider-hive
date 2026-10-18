import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_item.dart';

/// Persisted order stored in Firestore `orders/{orderId}`.
class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.uid,
    required this.userEmail,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.totalPrice,
    required this.totalQuantity,
    required this.paymentMethod,
    required this.items,
    this.status = 'placed',
    this.createdAt,
  });

  final String id;
  final String uid;
  final String userEmail;
  final String fullName;
  final String phone;
  final String address;
  final double totalPrice;
  final int totalQuantity;
  final String paymentMethod;
  final List<PlacedOrderLine> items;
  final String status;
  final DateTime? createdAt;

  String get paymentLabel => paymentMethod == 'cashOnDelivery'
      ? 'Cash on delivery'
      : paymentMethod;

  String get statusLabel {
    switch (status) {
      case 'preparing':
        return 'Preparing';
      case 'delivered':
        return 'Delivered';
      case 'placed':
      default:
        return 'Placed';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'userEmail': userEmail,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'totalPrice': totalPrice,
      'totalQuantity': totalQuantity,
      'paymentMethod': paymentMethod,
      'status': status,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory PlacedOrder.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? readTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    final rawItems = map['items'] as List<dynamic>? ?? const [];
    return PlacedOrder(
      id: (map['id'] as String?) ?? docId ?? '',
      uid: (map['uid'] as String?) ?? '',
      userEmail: (map['userEmail'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      totalQuantity: (map['totalQuantity'] as num?)?.toInt() ?? 0,
      paymentMethod: (map['paymentMethod'] as String?) ?? 'cashOnDelivery',
      status: (map['status'] as String?) ?? 'placed',
      items: rawItems
          .map((e) => PlacedOrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: readTime(map['createdAt']),
    );
  }

  factory PlacedOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PlacedOrder.fromMap(doc.data() ?? {}, docId: doc.id);
  }

  factory PlacedOrder.fromCheckout({
    required String id,
    required String uid,
    required String userEmail,
    required String fullName,
    required String phone,
    required String address,
    required double totalPrice,
    required int totalQuantity,
    required List<OrderItem> cartItems,
  }) {
    return PlacedOrder(
      id: id,
      uid: uid,
      userEmail: userEmail,
      fullName: fullName,
      phone: phone,
      address: address,
      totalPrice: totalPrice,
      totalQuantity: totalQuantity,
      paymentMethod: 'cashOnDelivery',
      status: 'placed',
      createdAt: DateTime.now(),
      items: cartItems
          .map(
            (item) => PlacedOrderLine(
              foodId: item.food.id,
              name: item.food.name,
              price: item.food.price,
              quantity: item.quantity,
              edition: item.selectedEdition,
              note: item.note,
            ),
          )
          .toList(),
    );
  }
}

class PlacedOrderLine {
  const PlacedOrderLine({
    required this.foodId,
    required this.name,
    required this.price,
    required this.quantity,
    this.edition,
    this.note,
  });

  final String foodId;
  final String name;
  final double price;
  final int quantity;
  final String? edition;
  final String? note;

  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'edition': edition,
      'note': note,
    };
  }

  factory PlacedOrderLine.fromMap(Map<String, dynamic> map) {
    return PlacedOrderLine(
      foodId: (map['foodId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      edition: map['edition'] as String?,
      note: map['note'] as String?,
    );
  }
}
