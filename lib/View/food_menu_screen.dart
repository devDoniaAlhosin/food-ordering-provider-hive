import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/food.dart';
import '../Provider/order_provider.dart';
import '../data/sample_foods.dart';
import '../extensions/text_field_extensions.dart';
import '../extensions/text_form_field_extensions.dart';
import 'cart_screen.dart';
import 'widgets/food_card.dart';

/// Food catalog screen (MVC View).
class FoodMenuScreen extends StatefulWidget {
  const FoodMenuScreen({super.key});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Food> get _filteredFoods {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sampleFoods;
    return sampleFoods.where((food) {
      return food.name.toLowerCase().contains(q) ||
          food.category.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showAddSheet(BuildContext context, Food food) async {
    final result = await showModalBottomSheet<_AddFoodResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _AddFoodSheet(food: food),
        );
      },
    );

    if (result != null && context.mounted) {
      await context.read<OrderProvider>().addItem(
            food,
            selectedEdition: result.selectedEdition,
            note: result.note,
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
    final foods = _filteredFoods;

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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: AppTextField.search(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
                Expanded(
                  child: foods.isEmpty
                      ? const Center(child: Text('No matching food items'))
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
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: foods.length,
                              itemBuilder: (context, index) {
                                final food = foods[index];
                                return FoodCard(
                                  food: food,
                                  onAdd: () => _showAddSheet(context, food),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AddFoodResult {
  const _AddFoodResult({this.selectedEdition, this.note});

  final String? selectedEdition;
  final String? note;
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.food});

  final Food food;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.food.editions.isNotEmpty
        ? widget.food.editions.first
        : null;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _AddFoodResult(
        selectedEdition: _selected,
        note: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(food.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              food.description.isEmpty ? food.category : food.description,
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
                  return ChoiceChip(
                    label: Text(edition),
                    selected: _selected == edition,
                    onSelected: (_) => setState(() => _selected = edition),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            AppTextFormField.notes(controller: _notesController),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to cart'),
            ),
          ],
        ),
      ),
    );
  }
}
