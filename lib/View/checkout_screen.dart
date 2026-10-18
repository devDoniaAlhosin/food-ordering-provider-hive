import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/checkout_order.dart';
import '../Provider/auth_provider.dart';
import '../Provider/order_provider.dart';
import '../Provider/user_provider.dart';
import '../extensions/text_form_field_extensions.dart';

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
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() => _submitting = true);

    final order = CheckoutOrder(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      totalPrice: cart.totalPrice,
      totalQuantity: cart.totalQuantity,
      userEmail: auth.user?.email ?? '',
      paymentMethod: PaymentMethod.cashOnDelivery,
    );

    await cart.clearCart();

    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order placed'),
        content: Text(
          'Thanks, ${order.fullName}!\n\n'
          'Payment: ${order.paymentLabel}\n'
          'Items: ${order.totalQuantity}\n'
          'Total: \$${order.totalPrice.toStringAsFixed(2)}\n\n'
          'Pay cash when your order arrives.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
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
