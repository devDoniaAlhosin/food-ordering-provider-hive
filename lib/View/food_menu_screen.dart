import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/food.dart';
import '../Provider/order_provider.dart';
import '../data/sample_foods.dart';
import 'cart_screen.dart';
import 'widgets/food_card.dart';

/// Food catalog screen (MVC View).
class FoodMenuScreen extends StatelessWidget {
  const FoodMenuScreen({super.key});

  Future<void> _showAddSheet(BuildContext context, Food food) async {
    String? selected =
        food.editions.isNotEmpty ? food.editions.first : null;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    food.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.description.isEmpty
                        ? food.category
                        : food.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${food.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (food.editions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Choose edition',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: food.editions.map((edition) {
                        final isSelected = selected == edition;
                        return ChoiceChip(
                          label: Text(edition),
                          selected: isSelected,
                          onSelected: (_) {
                            setSheetState(() => selected = edition);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to cart'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<OrderProvider>().addItem(
            food,
            selectedEdition: selected,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${food.name} added to cart'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<OrderProvider>().totalQuantity;
    final isLoading = context.watch<OrderProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Menu'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: IconButton(
                tooltip: 'Open cart',
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 900
                    ? 4
                    : width >= 600
                        ? 3
                        : 2;

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: sampleFoods.length,
                  itemBuilder: (context, index) {
                    final food = sampleFoods[index];
                    return FoodCard(
                      food: food,
                      onAdd: () => _showAddSheet(context, food),
                    );
                  },
                );
              },
            ),
    );
  }
}
