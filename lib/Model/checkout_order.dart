/// Delivery details for a cash-on-delivery checkout.
enum PaymentMethod { cashOnDelivery }

class CheckoutOrder {
  CheckoutOrder({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.totalPrice,
    required this.totalQuantity,
    required this.userEmail,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    DateTime? placedAt,
  }) : placedAt = placedAt ?? DateTime.now();

  final String fullName;
  final String phone;
  final String address;
  final double totalPrice;
  final int totalQuantity;
  final String userEmail;
  final PaymentMethod paymentMethod;
  final DateTime placedAt;

  String get paymentLabel => switch (paymentMethod) {
        PaymentMethod.cashOnDelivery => 'Cash on delivery',
      };
}
