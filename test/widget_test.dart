import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:w10_s20_food_ordering_provider_hive/Controller/order_controller.dart';
import 'package:w10_s20_food_ordering_provider_hive/Model/food.dart';
import 'package:w10_s20_food_ordering_provider_hive/Provider/order_provider.dart';
import 'package:w10_s20_food_ordering_provider_hive/View/food_menu_screen.dart';

void main() {
  testWidgets('Food menu shows sample items and cart icon', (tester) async {
    final provider = OrderProvider(controller: OrderController());

    await tester.pumpWidget(
      ChangeNotifierProvider<OrderProvider>.value(
        value: provider,
        child: const MaterialApp(home: FoodMenuScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Food Menu'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.text('Classic Burger'), findsOneWidget);
  });

  test('OrderController manages quantities and totals', () {
    final controller = OrderController();
    const food = Food(
      id: 'f1',
      name: 'Burger',
      category: 'Burgers',
      price: 10,
      imageUrl: 'https://example.com/b.jpg',
      editions: ['Regular', 'Double'],
    );

    expect(controller.addItem(food, selectedEdition: 'Regular'), isTrue);
    expect(controller.totalQuantity, 1);
    expect(controller.totalPrice, 10);

    expect(controller.increaseQuantity(0), isTrue);
    expect(controller.totalQuantity, 2);
    expect(controller.totalPrice, 20);

    expect(controller.decreaseQuantity(0), isTrue);
    expect(controller.totalQuantity, 1);

    expect(controller.addItem(food, quantity: 0), isFalse);
    expect(controller.removeItem(0), isTrue);
    expect(controller.isEmpty, isTrue);

    controller.addItem(food, selectedEdition: 'Double');
    controller.clearCart();
    expect(controller.isEmpty, isTrue);
  });
}
