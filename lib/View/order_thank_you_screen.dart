import 'package:flutter/material.dart';

import '../Model/placed_order.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// Full-screen thank-you page after a successful checkout.
class OrderThankYouScreen extends StatefulWidget {
  const OrderThankYouScreen({
    super.key,
    required this.order,
    this.onViewOrders,
  });

  final PlacedOrder order;
  final VoidCallback? onViewOrders;

  @override
  State<OrderThankYouScreen> createState() => _OrderThankYouScreenState();
}

class _OrderThankYouScreenState extends State<OrderThankYouScreen>
    with TickerProviderStateMixin {
  late final AnimationController _iconController;
  late final AnimationController _contentController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  PlacedOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _iconScale = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconFade = CurvedAnimation(parent: _iconController, curve: Curves.easeOut);
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _iconController.forward();
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Just now';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d · $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE8D6), AppTheme.cream],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeTransition(
                  opacity: _iconFade,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Center(
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 68,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Thank you!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your order was placed successfully, ${order.fullName}.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order summary',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _Row(
                                label: 'Order ID',
                                value: order.id.length > 10
                                    ? '${order.id.substring(0, 10)}…'
                                    : order.id,
                              ),
                              _Row(label: 'Status', value: order.statusLabel),
                              _Row(label: 'Payment', value: order.paymentLabel),
                              _Row(
                                label: 'Items',
                                value: '${order.totalQuantity}',
                              ),
                              _Row(
                                label: 'Total',
                                value:
                                    '\$${order.totalPrice.toStringAsFixed(2)}',
                                emphasize: true,
                              ),
                              _Row(
                                label: 'Placed',
                                value: _formatDate(order.createdAt),
                              ),
                              const Divider(height: 24),
                              Text(
                                'Delivery',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(order.phone, style: theme.textTheme.bodyMedium),
                              Text(
                                order.address,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (order.items.isNotEmpty) ...[
                                const Divider(height: 24),
                                Text(
                                  'Items',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...order.items.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${line.quantity}× ${line.name}'
                                            '${line.edition != null && line.edition!.isNotEmpty ? ' (${line.edition})' : ''}',
                                          ),
                                        ),
                                        Text(
                                          '\$${line.lineTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pay cash when your order arrives.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            widget.onViewOrders?.call();
                          },
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('View my orders'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            MainShell.goToMenu();
                          },
                          icon: const Icon(Icons.restaurant_menu_outlined),
                          label: const Text('Back to menu'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
