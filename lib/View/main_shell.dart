import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/order_provider.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';
import 'food_menu_screen.dart';
import 'orders_list_screen.dart';
import 'profile_screen.dart';

/// Root shell with Material 3 bottom navigation for mobile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Allows other screens (e.g. thank-you) to switch tabs after popping.
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static void goToMenu() => tabIndex.value = 0;
  static void goToCart() => tabIndex.value = 1;
  static void goToOrders() => tabIndex.value = 2;
  static void goToProfile() => tabIndex.value = 3;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = MainShell.tabIndex.value;
    MainShell.tabIndex.addListener(_onExternalTabChange);
  }

  void _onExternalTabChange() {
    final next = MainShell.tabIndex.value;
    if (!mounted || next == _index) return;
    setState(() => _index = next);
  }

  @override
  void dispose() {
    MainShell.tabIndex.removeListener(_onExternalTabChange);
    super.dispose();
  }

  void _goTo(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    MainShell.tabIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<OrderProvider>().totalQuantity;
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          FoodMenuScreen(
            onOpenCart: () => _goTo(1),
            onOpenProfile: () => _goTo(3),
          ),
          const CartScreen(),
          const OrdersListScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _goTo,
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppTheme.peach,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'Menu',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: Icon(
                    Icons.shopping_cart,
                    color: theme.colorScheme.primary,
                  ),
                ),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
