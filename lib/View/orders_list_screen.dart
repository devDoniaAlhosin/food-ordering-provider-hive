import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Model/placed_order.dart';
import '../Provider/orders_provider.dart';
import '../theme/app_theme.dart';

/// Table / list of the signed-in user's orders from Firestore.
class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'preparing':
        return Colors.orange.shade700;
      case 'delivered':
        return Colors.green.shade700;
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: orders.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: orders.isLoading && orders.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : orders.orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No orders yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Place an order from the menu and it will show here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      '${orders.orders.length} order'
                      '${orders.orders.length == 1 ? '' : 's'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Header row (table-like)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.peach,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Order',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Items',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total',
                              textAlign: TextAlign.end,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...orders.orders.map(
                      (order) => _OrderCard(
                        order: order,
                        dateLabel: _formatDate(order.createdAt),
                        statusColor: _statusColor(context, order.status),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.dateLabel,
    required this.statusColor,
  });

  final PlacedOrder order;
  final String dateLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$shortId',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('${order.totalQuantity}'),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '\$${order.totalPrice.toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.statusLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Payment: ${order.paymentLabel}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Deliver to: ${order.address}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${line.quantity}× ${line.name}'
                      '${line.edition != null && line.edition!.isNotEmpty ? ' (${line.edition})' : ''}',
                    ),
                  ),
                  Text('\$${line.lineTotal.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
