import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/order_provider.dart';
import '../extensions/text_form_field_extensions.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';
import 'main_shell.dart';

/// Shopping cart screen (MVC View).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (!provider.isEmpty)
            IconButton(
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Clear cart?'),
                    content: const Text(
                      'This removes all items from your cart.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<OrderProvider>().clearCart();
                }
              },
            ),
        ],
      ),
      body: provider.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: provider.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.food.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          ColoredBox(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: const SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Icon(Icons.fastfood),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.food.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      [
                                        if (item.selectedEdition != null)
                                          item.selectedEdition!,
                                        '\$${item.food.price.toStringAsFixed(2)} each',
                                      ].join(' · '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if (item.note != null &&
                                        item.note!.isNotEmpty)
                                      Text(
                                        item.note!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Decrease',
                                onPressed: () => context
                                    .read<OrderProvider>()
                                    .decreaseQuantity(index),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 52,
                                child: _QuantityField(
                                  key: ValueKey(
                                    'qty-${item.cartKey}-${item.quantity}',
                                  ),
                                  index: index,
                                  quantity: item.quantity,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase',
                                onPressed: () => context
                                    .read<OrderProvider>()
                                    .increaseQuantity(index),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () => context
                                    .read<OrderProvider>()
                                    .removeItem(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items',
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              '${provider.totalQuantity}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${provider.totalPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Compact quantity editor built with [AppTextFormField.quantity].
class _QuantityField extends StatefulWidget {
  const _QuantityField({
    super.key,
    required this.index,
    required this.quantity,
  });

  final int index;
  final int quantity;

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _controller.text = '${widget.quantity}';
      return;
    }
    final value = int.parse(_controller.text.trim());
    if (value == widget.quantity) return;
    await context.read<OrderProvider>().setQuantity(widget.index, value);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AppTextFormField.quantity(
        controller: _controller,
        onEditingComplete: _apply,
        onFieldSubmitted: (_) => _apply(),
      ),
    );
  }
}

class _EmptyCart extends StatefulWidget {
  const _EmptyCart();

  @override
  State<_EmptyCart> createState() => _EmptyCartState();
}

class _EmptyCartState extends State<_EmptyCart> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;

  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );
    _iconScale = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.elasticOut),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _browseMenu(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      MainShell.goToMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE8D6), AppTheme.cream],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _floatController,
                      _pulseController,
                      _iconScale,
                    ]),
                    builder: (context, child) {
                      final floatY = (_floatController.value - 0.5) * 14;
                      final pulse = 0.85 + (_pulseController.value * 0.2);
                      return Transform.translate(
                        offset: Offset(0, floatY),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: pulse * 1.35,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.peach.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: pulse,
                              child: Container(
                                width: 118,
                                height: 118,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                            ),
                            ScaleTransition(
                              scale: _iconScale,
                              child: child,
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        size: 44,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Your cart is empty',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Looks like you haven\'t added anything yet.\nBrowse the menu and pick a favorite.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _EmptyHintChip(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Hot picks',
                      ),
                      _EmptyHintChip(
                        icon: Icons.restaurant_menu_outlined,
                        label: 'Fresh menu',
                      ),
                      _EmptyHintChip(
                        icon: Icons.bolt_outlined,
                        label: 'Fast checkout',
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _browseMenu(context),
                      icon: const Icon(Icons.restaurant_menu_rounded),
                      label: const Text('Browse menu'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your picks will show up here',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHintChip extends StatelessWidget {
  const _EmptyHintChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
