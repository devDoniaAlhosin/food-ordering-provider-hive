import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/food.dart';
import '../Provider/auth_provider.dart';
import '../Provider/order_provider.dart';
import '../Provider/user_provider.dart';
import '../data/sample_foods.dart';
import '../extensions/text_field_extensions.dart';
import '../extensions/text_form_field_extensions.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'users_list_screen.dart';
import 'widgets/food_card.dart';

/// Food catalog screen (MVC View).
class FoodMenuScreen extends StatefulWidget {
  const FoodMenuScreen({super.key});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  static const String _allCategory = 'All';

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = _allCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = sampleFoods.map((f) => f.category).toSet().toList()..sort();
    return [_allCategory, ...cats];
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Burgers':
        return Icons.lunch_dining_outlined;
      case 'Pizza':
        return Icons.local_pizza_outlined;
      case 'Wraps':
        return Icons.ramen_dining_outlined;
      case 'Salads':
        return Icons.eco_outlined;
      case 'Sushi':
        return Icons.set_meal_outlined;
      case 'Drinks':
        return Icons.local_cafe_outlined;
      case 'Pasta':
        return Icons.dining_outlined;
      case 'Sides':
        return Icons.fastfood_outlined;
      case _allCategory:
        return Icons.restaurant_menu_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  List<Food> get _filteredFoods {
    final q = _query.trim().toLowerCase();
    return sampleFoods.where((food) {
      final matchesCategory = _selectedCategory == _allCategory ||
          food.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (q.isEmpty) return true;
      return food.name.toLowerCase().contains(q) ||
          food.category.toLowerCase().contains(q) ||
          food.description.toLowerCase().contains(q);
    }).toList();
  }

  String? get _greetingName {
    try {
      final profile = context.watch<UserProvider>().currentProfile;
      if (profile != null && profile.fullName.trim().isNotEmpty) {
        return profile.fullName.trim().split(' ').first;
      }
      final auth = context.watch<AppAuthProvider>();
      if (!auth.isLoggedIn) return null;
      final user = auth.user!;
      if (user.displayName?.trim().isNotEmpty ?? false) {
        return user.displayName!.trim().split(' ').first;
      }
      return user.email?.split('@').first;
    } catch (_) {
      return null;
    }
  }

  List<Widget> _authActions(BuildContext context) {
    AppAuthProvider auth;
    UserProvider? users;
    try {
      auth = context.watch<AppAuthProvider>();
      users = context.watch<UserProvider>();
    } catch (_) {
      return const [];
    }
    if (!auth.isLoggedIn) return const [];

    final user = auth.user!;
    final profile = users.currentProfile;
    final displayName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : ((user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'User'));
    final isAdmin = users.isAdmin;

    return [
      PopupMenuButton<String>(
        tooltip: 'Profile',
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (value) async {
          if (value == 'logout') {
            await auth.logout();
          } else if (value == 'profile') {
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
          } else if (value == 'users' && isAdmin) {
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UsersListScreen(),
              ),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  isAdmin ? 'Role: admin' : 'Role: user',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'profile',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline),
              title: Text('My profile'),
              dense: true,
            ),
          ),
          if (isAdmin)
            const PopupMenuItem<String>(
              value: 'users',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.admin_panel_settings_outlined),
                title: Text('Manage users'),
                dense: true,
              ),
            ),
          const PopupMenuItem<String>(
            value: 'logout',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout),
              title: Text('Sign out'),
              dense: true,
            ),
          ),
        ],
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
    ];
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
    final name = _greetingName;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name == null ? 'Food Menu' : 'Hi, $name',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'What are you craving today?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          ..._authActions(context),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: IconButton.filledTonal(
                tooltip: 'Open cart',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.peach,
                ),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.peach,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.storefront_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tonight\'s kitchen',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'Fresh dishes · open for orders',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppTextField.search(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _query = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final selected = category == _selectedCategory;
                      return FilterChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(
                          _categoryIcon(category),
                          size: 18,
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                        label: Text(category),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : AppTheme.ink,
                        ),
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                        ),
                        onSelected: (_) {
                          setState(() => _selectedCategory = category);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        _selectedCategory == _allCategory
                            ? 'Full menu'
                            : _selectedCategory,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${foods.length} dish${foods.length == 1 ? '' : 'es'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: foods.isEmpty
                      ? _EmptySearch(
                          query: _query,
                          category: _selectedCategory,
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 900
                                ? 4
                                : width >= 600
                                    ? 3
                                    : 2;

                            return GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.66,
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

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({
    required this.query,
    required this.category,
  });

  final String query;
  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'No matches for "$query"'
                  : 'No dishes in $category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try another search or menu category',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
    _selected =
        widget.food.editions.isNotEmpty ? widget.food.editions.first : null;
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
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    food.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: AppTheme.peach,
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(Icons.fastfood),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food.description.isEmpty
                            ? food.category
                            : food.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${food.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (food.editions.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Choose edition',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
