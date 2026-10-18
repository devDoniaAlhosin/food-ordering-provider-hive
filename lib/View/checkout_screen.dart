import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/app_notification.dart';
import '../Model/order_item.dart';
import '../Provider/auth_provider.dart';
import '../Provider/order_provider.dart';
import '../Provider/orders_provider.dart';
import '../Provider/user_provider.dart';
import '../Services/notification_service.dart';
import '../extensions/text_form_field_extensions.dart';
import 'main_shell.dart';
import 'order_thank_you_screen.dart';

/// Checkout with cash on delivery only.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  void _prefillFromProfile() {
    if (!mounted) return;
    final profile = context.read<UserProvider>().currentProfile;
    final authUser = context.read<AppAuthProvider>().user;
    if (profile != null) {
      if (profile.fullName.isNotEmpty) {
        _nameController.text = profile.fullName;
      }
      if (profile.phone.isNotEmpty) {
        _phoneController.text = profile.phone;
      }
      if (profile.address.isNotEmpty) {
        _addressController.text = profile.address;
      }
      return;
    }
    if (authUser?.displayName != null) {
      _nameController.text = authUser!.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cart = context.read<OrderProvider>();
    final auth = context.read<AppAuthProvider>();
    final orders = context.read<OrdersProvider>();
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    final uid = auth.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order')),
      );
      return;
    }

    setState(() => _submitting = true);

    final cartSnapshot = cart.items
        .map(
          (item) => OrderItem(
            food: item.food,
            quantity: item.quantity,
            selectedEdition: item.selectedEdition,
            note: item.note,
          ),
        )
        .toList();
    final totalPrice = cart.totalPrice;
    final totalQuantity = cart.totalQuantity;

    final saved = await orders.placeOrder(
      uid: uid,
      userEmail: auth.user?.email ?? '',
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      totalPrice: totalPrice,
      totalQuantity: totalQuantity,
      cartItems: cartSnapshot,
    );

    if (!mounted) return;

    if (saved == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orders.errorMessage ?? 'Could not place order'),
        ),
      );
      return;
    }

    await cart.clearCart();

    try {
      await NotificationService.instance.showLocalNotification(
        AppNotification(
          title: 'Order placed',
          body:
              'Thanks, ${saved.fullName}! '
              '${saved.totalQuantity} item(s) · '
              '\$${saved.totalPrice.toStringAsFixed(2)} · '
              '${saved.paymentLabel}. Pay when it arrives.',
          data: {
            'type': 'order_placed',
            'orderId': saved.id,
            'total': saved.totalPrice.toStringAsFixed(2),
          },
        ),
      );
    } catch (_) {
      // Notification failure should not block checkout.
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderThankYouScreen(
          order: saved,
          onViewOrders: MainShell.goToOrders,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<OrderProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    'Delivery details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextFormField.fullName(controller: _nameController),
                  const SizedBox(height: 14),
                  AppTextFormField.phone(controller: _phoneController),
                  const SizedBox(height: 14),
                  AppTextFormField.address(controller: _addressController),
                  const SizedBox(height: 24),
                  Text(
                    'Payment method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: theme.colorScheme.surfaceContainerLow,
                    child: ListTile(
                      leading: Icon(
                        Icons.payments_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Cash on delivery'),
                      subtitle: const Text(
                        'Pay with cash when the order arrives',
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items'),
                            Text('${cart.totalQuantity}'),
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
                              '\$${cart.totalPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _placeOrder,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _submitting ? 'Placing order...' : 'Place order (COD)',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
