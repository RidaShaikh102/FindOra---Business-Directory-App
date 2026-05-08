import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/analytics_service.dart';
import '../../services/local_storage_service.dart';

/// Super-admin view: all marketplace orders, COD totals, commission & seller estimates.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final LocalStorageService _storage = LocalStorageService();
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  List<OrderModel> _orders = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('AdminOrdersScreen');
    _sub = _storage.watchAllOrders().listen(
      (raw) {
        if (!mounted) return;
        setState(() {
          _orders = raw.map(OrderModel.fromJson).toList();
          _loading = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  double get _totalCommission => _orders.fold<double>(
        0,
        (s, o) => s + (o.isDelivered ? o.commission : 0),
      );

  double get _totalSellerEarnings => _orders.fold<double>(
        0,
        (s, o) => s + (o.isDelivered ? o.sellerEarning : 0),
      );

  double get _grossDelivered => _orders.fold<double>(
        0,
        (s, o) => s + (o.isDelivered ? o.effectiveTotal : 0),
      );

  List<OrderModel> get _filtered {
    if (_filter == 'all') return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return RefreshIndicator(
      onRefresh: () async {
        final list = await _storage.getAllOrders();
        if (!mounted) return;
        setState(() {
          _orders = list.map(OrderModel.fromJson).toList();
        });
      },
      color: Colors.teal.shade700,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(
            title: 'Delivered (COD) gross',
            value: 'Rs. ${_money(_grossDelivered)}',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 10),
          _summaryCard(
            title: 'Platform commission (10%)',
            value: 'Rs. ${_money(_totalCommission)}',
            icon: Icons.percent_outlined,
          ),
          const SizedBox(height: 10),
          _summaryCard(
            title: 'Seller earnings (after commission)',
            value: 'Rs. ${_money(_totalSellerEarnings)}',
            icon: Icons.store_mall_directory_outlined,
          ),
          const SizedBox(height: 16),
          const Text(
            'Filter',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('all', 'All'),
              ...kAllOrderStatusFilters.map(
                (s) => _chip(s, orderStatusLabel(s)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No orders match this filter.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ..._filtered.map(_orderTile),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final sel = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal.shade800,
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A2D3F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTile(OrderModel o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: ExpansionTile(
        title: Text(
          o.businessName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '#${o.id} • ${orderStatusLabel(o.status)} • ${o.deliveryMode}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Customer', o.customerName),
                _row('Email', o.customerEmail),
                _row('Phone', o.customerPhone),
                _row('Seller', o.ownerEmail),
                _row('Total (COD)', 'Rs. ${_money(o.effectiveTotal)}'),
                if (o.courierTrackingId.isNotEmpty)
                  _row('Tracking', o.courierTrackingId),
                if (o.isDelivered && o.commission > 0) ...[
                  _row('Commission', 'Rs. ${_money(o.commission)}'),
                  _row('Seller earning', 'Rs. ${_money(o.sellerEarning)}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(v.isEmpty ? '—' : v)),
        ],
      ),
    );
  }

  String _money(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
