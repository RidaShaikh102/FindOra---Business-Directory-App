import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final AuthService _authService = AuthService();

  bool _loading = true;
  String _selectedStatus = 'all';
  List<OrderModel> _orders = <OrderModel>[];
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSub;

  @override
  void initState() {
    super.initState();
    _subscribeOrders();
    AnalyticsService.logScreenView('MyOrdersScreen');
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }

  Future<void> _subscribeOrders() async {
    await _ordersSub?.cancel();
    if (!mounted) return;
    setState(() => _loading = true);
    final email = await _authService.getCurrentUserEmail() ?? '';
    _ordersSub = _storageService.watchOrdersByCustomer(email).listen(
      (raw) {
        if (!mounted) return;
        setState(() {
          _orders = raw.map(OrderModel.fromJson).toList();
          _loading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
        );
      },
    );
  }

  Future<void> _loadOrders() async => _subscribeOrders();

  List<OrderModel> get _filteredOrders {
    if (_selectedStatus == 'all') return _orders;
    return _orders.where((order) => order.status == _selectedStatus).toList();
  }

  int get _activeCount =>
      _orders.where((order) => orderStatusIsActive(order.status)).length;

  Future<void> _cancelOrder(OrderModel order) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'This will notify the business that you no longer want this order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    try {
      await _storageService.updateOrderStatus(
        order.id,
        'cancelled',
        actor: 'customer',
        message: 'Customer cancelled the order',
      );
      await AnalyticsService.logAction('cancel_order');
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel order: $e')));
    }
  }

  Future<void> _reorder(OrderModel order) async {
    try {
      final liveServices = await _storageService.getServiceModelsByIds(
        order.businessId,
        order.items.map((item) => item.serviceId),
      );
      final servicesById = {
        for (final service in liveServices) service.id: service,
      };
      final availableItems = <CartItemModel>[];
      final unavailableNames = <String>[];

      for (final item in order.items) {
        final service = servicesById[item.serviceId];
        if (service == null || !service.isAvailable) {
          unavailableNames.add(item.name);
          continue;
        }
        availableItems.add(
          CartItemModel(service: service, quantity: item.quantity),
        );
      }

      if (availableItems.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'None of the original items are currently available to reorder.',
            ),
          ),
        );
        return;
      }

      final currentCart = ref.read(cartProvider);
      if (currentCart.items.isNotEmpty) {
        final shouldReplace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace current cart?'),
            content: const Text(
              'Reordering will replace the items already in your cart.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep current cart'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Replace cart'),
              ),
            ],
          ),
        );

        if (shouldReplace != true) return;
      }

      ref
          .read(cartProvider.notifier)
          .replaceWithItems(
            businessId: order.businessId,
            businessName: order.businessName,
            ownerEmail: order.ownerEmail,
            items: availableItems,
          );
      await AnalyticsService.logAction('reorder_order');

      if (!mounted) return;
      final message = unavailableNames.isEmpty
          ? 'Cart updated from your previous order.'
          : 'Cart updated. Some items were skipped: ${unavailableNames.join(', ')}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reorder: $e')));
    }
  }

  void _openOrderDetails(OrderModel order) {
    final history = _historyFor(order);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.businessName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    _statusPill(order.status),
                  ],
                ),
                const SizedBox(height: 18),
                _detailBlock(
                  title: 'Items',
                  child: Column(
                    children: order.items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.name} x${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rs. ${_formatPrice(item.totalPrice)}',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _detailBlock(
                  title: 'Tracking',
                  child: Column(
                    children: history
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _statusColor(event.status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (event != history.last)
                                      Container(
                                        width: 2,
                                        height: 38,
                                        color: Colors.grey.shade300,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orderStatusLabel(event.status),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        event.message.isEmpty
                                            ? orderStatusLabel(event.status)
                                            : event.message,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDateTime(event.timestamp),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _detailBlock(
                  title: 'Fulfillment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryRow(
                        'ETA',
                        order.hasEta
                            ? _formatDateTime(order.estimatedReadyAt)
                            : 'Not set yet',
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Owner note',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.ownerNote.trim().isEmpty
                            ? 'The business has not added a fulfillment note yet.'
                            : order.ownerNote,
                      ),
                    ],
                  ),
                ),
                if (order.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailBlock(title: 'Your note', child: Text(order.note)),
                ],
                const SizedBox(height: 12),
                _detailBlock(
                  title: 'Summary',
                  child: Column(
                    children: [
                      _summaryRow('Items', '${order.itemCount}'),
                      const SizedBox(height: 8),
                      _summaryRow(
                        'Subtotal',
                        'Rs. ${_formatPrice(order.subtotal)}',
                      ),
                      if (order.deliveryFee > 0) ...[
                        const SizedBox(height: 8),
                        _summaryRow(
                          'Delivery',
                          'Rs. ${_formatPrice(order.deliveryFee)}',
                        ),
                      ],
                      const SizedBox(height: 8),
                      _summaryRow(
                        'Total (COD)',
                        'Rs. ${_formatPrice(order.effectiveTotal)}',
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        'Delivery type',
                        order.deliveryMode == 'local'
                            ? 'Local delivery'
                            : 'Courier (COD)',
                      ),
                      if (order.courierTrackingId.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _summaryRow('Tracking', order.courierTrackingId),
                      ],
                      if (order.isDelivered && order.commission > 0) ...[
                        const SizedBox(height: 8),
                        _summaryRow(
                          'Platform fee (est.)',
                          'Rs. ${_formatPrice(order.commission)}',
                        ),
                      ],
                      const SizedBox(height: 8),
                      _summaryRow('Placed', _formatDateTime(order.createdAt)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statColumn(
                            'Total',
                            _orders.length.toString(),
                          ),
                        ),
                        Expanded(
                          child: _statColumn('Active', _activeCount.toString()),
                        ),
                        Expanded(
                          child: _statColumn(
                            'Delivered',
                            _orders
                                .where(
                                  (order) =>
                                      order.status == 'delivered' ||
                                      order.status == 'completed',
                                )
                                .length
                                .toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip('all', 'All'),
                      ...kAllOrderStatusFilters.map(
                        (status) => _buildStatusChip(
                          status,
                          orderStatusLabel(status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_filteredOrders.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredOrders.map(_buildOrderCard),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final firstItems = order.items.take(2).map((item) => item.name).join(', ');
    final moreCount = order.items.length > 2 ? order.items.length - 2 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.businessName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              _statusPill(order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            moreCount > 0 ? '$firstItems +$moreCount more' : firstItems,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 18, color: Colors.teal),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(order.createdAt),
                style: const TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              Text(
                'Rs. ${_formatPrice(order.effectiveTotal)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (order.hasEta || order.ownerNote.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.hasEta)
                  _metaChip(
                    Icons.schedule_outlined,
                    'ETA ${_formatTimeOnly(order.estimatedReadyAt)}',
                  ),
                if (order.ownerNote.trim().isNotEmpty)
                  _metaChip(Icons.sticky_note_2_outlined, 'Owner note'),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openOrderDetails(order),
                  child: const Text('Track order'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _reorder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2D3F),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reorder'),
                ),
              ),
            ],
          ),
          if (order.canCustomerCancel) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _cancelOrder(order),
                child: const Text(
                  'Cancel order',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final selected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedStatus = status),
      selectedColor: Colors.teal,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
    );
  }

  Widget _statusPill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2D3F).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0A2D3F)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0A2D3F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _detailBlock({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Once you place an order, you\'ll be able to track it here and reorder in one tap.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  List<OrderStatusEventModel> _historyFor(OrderModel order) {
    if (order.statusHistory.isNotEmpty) {
      final history = [...order.statusHistory];
      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return history;
    }

    final history = <OrderStatusEventModel>[
      OrderStatusEventModel(
        status: 'pending',
        timestamp: order.createdAt,
        actor: 'customer',
        message: 'Order placed',
      ),
    ];

    if (order.status != 'pending') {
      history.add(
        OrderStatusEventModel(
          status: order.status,
          timestamp: order.updatedAt > 0 ? order.updatedAt : order.createdAt,
          actor: 'system',
          message: 'Order updated to ${orderStatusLabel(order.status)}',
        ),
      );
    }

    return history;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
      case 'out_for_delivery':
        return Colors.orange;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      case 'pending':
      default:
        return Colors.teal;
    }
  }

  String _formatDateTime(int timestamp) {
    if (timestamp <= 0) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _formatTimeOnly(int timestamp) {
    if (timestamp <= 0) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
