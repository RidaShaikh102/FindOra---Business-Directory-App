import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage_service.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
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
    AnalyticsService.logScreenView('ManageOrdersScreen');
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }

  int get _pendingCount =>
      _orders.where((order) => order.status == 'pending').length;

  int get _activeCount => _orders
      .where((order) => orderStatusIsActive(order.status))
      .length;

  int get _completedCount => _orders
      .where(
        (order) => order.status == 'delivered' || order.status == 'completed',
      )
      .length;

  List<OrderModel> get _filteredOrders {
    if (_selectedStatus == 'all') return _orders;
    return _orders.where((order) => order.status == _selectedStatus).toList();
  }

  Future<void> _subscribeOrders() async {
    await _ordersSub?.cancel();
    if (!mounted) return;
    setState(() => _loading = true);
    final ownerEmail = await _authService.getCurrentUserEmail() ?? '';
    _ordersSub = _storageService.watchOrdersForOwner(ownerEmail).listen(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
      },
    );
  }

  Future<void> _loadOrders() async => _subscribeOrders();

  Future<void> _updateOrderStatus(OrderModel order, String nextStatus) async {
    if (order.status == nextStatus) return;

    try {
      await _storageService.updateOrderStatus(
        order.id,
        nextStatus,
        actor: 'owner',
      );
      await AnalyticsService.logAction('owner_update_order_status');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update order: $e')));
    }
  }

  Future<void> _editCourierTracking(OrderModel order) async {
    final carrierController = TextEditingController(text: order.courierCarrier);
    final trackingController =
        TextEditingController(text: order.courierTrackingId);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Courier / tracking (manual)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: carrierController,
              decoration: const InputDecoration(
                labelText: 'Carrier name',
                hintText: 'e.g. TCS, Leopard',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking ID',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _storageService.updateOrderCourierMeta(
        order.id,
        courierCarrier: carrierController.text,
        courierTrackingId: trackingController.text,
      );
      await AnalyticsService.logAction('owner_update_courier_meta');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save tracking: $e')),
      );
    } finally {
      carrierController.dispose();
      trackingController.dispose();
    }
  }

  Future<void> _editFulfillment(OrderModel order) async {
    final noteController = TextEditingController(text: order.ownerNote);
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentMinutes = order.hasEta
        ? ((order.estimatedReadyAt - now) / Duration.millisecondsPerMinute)
              .ceil()
        : 0;
    final etaController = TextEditingController(
      text: currentMinutes > 0 ? '$currentMinutes' : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update fulfillment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Owner note',
                hintText: 'Pickup instructions or preparation update',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: etaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ETA in minutes',
                hintText: 'e.g. 20',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final etaMinutes = int.tryParse(etaController.text.trim()) ?? 0;
    final estimatedReadyAt = etaMinutes > 0
        ? DateTime.now().millisecondsSinceEpoch +
              (etaMinutes * Duration.millisecondsPerMinute)
        : 0;

    try {
      await _storageService.updateOrderFulfillment(
        order.id,
        ownerNote: noteController.text.trim(),
        estimatedReadyAt: estimatedReadyAt,
      );
      await AnalyticsService.logAction('owner_update_order_fulfillment');
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update fulfillment: $e')),
      );
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
          initialChildSize: 0.78,
          minChildSize: 0.55,
          maxChildSize: 0.94,
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
                const SizedBox(height: 16),
                _detailBlock(
                  title: 'Customer',
                  child: Column(
                    children: [
                      _infoRow(Icons.person_outline, order.customerName),
                      _infoRow(Icons.phone_outlined, order.customerPhone),
                      _infoRow(Icons.email_outlined, order.customerEmail),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                  title: 'Fulfillment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryRow(
                        'ETA',
                        order.hasEta
                            ? _formatDateTime(order.estimatedReadyAt)
                            : 'Not set',
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Owner note',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.ownerNote.trim().isEmpty
                            ? 'No fulfillment note added yet.'
                            : order.ownerNote,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                if (order.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailBlock(title: 'Customer note', child: Text(order.note)),
                ],
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
                  title: 'Actions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (order.status == 'pending')
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _updateOrderStatus(order, 'accepted');
                          },
                          child: const Text('Accept order'),
                        ),
                      if (_canMarkDelivered(order.status)) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _updateOrderStatus(order, 'delivered');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Mark delivered (COD)'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _editCourierTracking(order);
                        },
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('Courier / tracking (manual)'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Set status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kAllOrderStatusFilters
                            .map(
                              (status) => ChoiceChip(
                                label: Text(orderStatusLabel(status)),
                                selected: order.status == status,
                                selectedColor: Colors.teal,
                                labelStyle: TextStyle(
                                  color: order.status == status
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onSelected: (_) async {
                                  Navigator.of(context).pop();
                                  await _updateOrderStatus(order, status);
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _editFulfillment(order);
                          },
                          icon: const Icon(Icons.edit_calendar_outlined),
                          label: const Text('Edit fulfillment details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2D3F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
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
        title: const Text(
          'Manage Orders',
          style: TextStyle(color: Colors.white),
        ),
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
                            'Pending',
                            _pendingCount.toString(),
                          ),
                        ),
                        Expanded(
                          child: _statColumn('Active', _activeCount.toString()),
                        ),
                        Expanded(
                          child: _statColumn(
                            'Delivered',
                            _completedCount.toString(),
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
    final itemsLabel = order.items
        .take(2)
        .map((item) => '${item.name} x${item.quantity}')
        .join(', ');
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
                      order.customerName.isEmpty
                          ? '#${order.id}'
                          : '${order.customerName}  •  #${order.id}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (status) => _updateOrderStatus(order, status),
                itemBuilder: (context) => kAllOrderStatusFilters
                    .map(
                      (status) => PopupMenuItem<String>(
                        value: status,
                        child: Text(orderStatusLabel(status)),
                      ),
                    )
                    .toList(),
                child: _statusPill(order.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            moreCount > 0 ? '$itemsLabel +$moreCount more' : itemsLabel,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 18, color: Colors.teal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customerPhone.isEmpty ? '-' : order.customerPhone,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
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
                  _metaChip(Icons.sticky_note_2_outlined, 'Note added'),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openOrderDetails(order),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _editFulfillment(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2D3F),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fulfillment'),
                ),
              ),
            ],
          ),
          if (order.status == 'pending') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order, 'accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept order'),
              ),
            ),
          ],
          if (_canMarkDelivered(order.status)) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _updateOrderStatus(order, 'delivered'),
                child: const Text('Mark delivered'),
              ),
            ),
          ],
          if (order.deliveryMode == 'courier' ||
              order.courierTrackingId.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _editCourierTracking(order),
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('Courier / tracking'),
            ),
          ],
        ],
      ),
    );
  }

  bool _canMarkDelivered(String status) {
    const ready = {
      'accepted',
      'confirmed',
      'in_progress',
      'out_for_delivery',
    };
    return ready.contains(status);
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

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.isEmpty ? '-' : text,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'New customer orders will appear here so you can confirm and track them.',
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

    return <OrderStatusEventModel>[
      OrderStatusEventModel(
        status: order.status,
        timestamp: order.createdAt,
        actor: 'system',
        message: 'Order created',
      ),
    ];
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
