import 'package:flutter/material.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/widgets/responsive_layout.dart';

class ManageBusinessesScreen extends StatefulWidget {
  const ManageBusinessesScreen({super.key});

  @override
  State<ManageBusinessesScreen> createState() => _ManageBusinessesScreenState();
}

class _ManageBusinessesScreenState extends State<ManageBusinessesScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Map<String, dynamic>> _allBusinesses = [];
  List<Map<String, dynamic>> _filteredBusinesses = [];
  bool _loading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    final list = await _storageService.getBusinesses();
    setState(() {
      _allBusinesses = list;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    bool isApproved(Map<String, dynamic> b) {
      final status = b['status'];
      return status == null || status == 'approved';
    }

    if (_filter == 'all') {
      _filteredBusinesses = List<Map<String, dynamic>>.from(_allBusinesses);
    } else if (_filter == 'pending') {
      _filteredBusinesses = _allBusinesses
          .where((b) => b['status'] == 'pending')
          .toList();
    } else if (_filter == 'approved') {
      _filteredBusinesses = _allBusinesses.where((b) => isApproved(b)).toList();
    }
  }

  Future<void> _setStatus(int index, String status) async {
    final updated = Map<String, dynamic>.from(_filteredBusinesses[index]);
    updated['status'] = status;
    final allIndex = _allBusinesses.indexWhere((b) => b['id'] == updated['id']);
    if (allIndex != -1) {
      _allBusinesses[allIndex] = updated;
      final businessId = updated['id']?.toString();
      if (businessId != null && businessId.isNotEmpty) {
        await _storageService.updateBusiness(businessId, updated);
      }
    }
    if (status == 'approved') {
      await AnalyticsService.logAction('business_approved');
    } else if (status == 'rejected') {
      await AnalyticsService.logAction('business_rejected');
    } else if (status == 'pending') {
      await AnalyticsService.logAction('business_pending');
    }
    if (mounted) {
      setState(() {
        _applyFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        ToggleButtons(
          isSelected: [
            _filter == 'pending',
            _filter == 'all',
            _filter == 'approved',
          ],
          onPressed: (index) {
            setState(() {
              if (index == 0) _filter = 'pending';
              if (index == 1) _filter = 'all';
              if (index == 2) _filter = 'approved';
              _applyFilter();
            });
          },
          color: Colors.teal,
          selectedColor: Colors.white,
          fillColor: Colors.teal,
          borderRadius: BorderRadius.circular(10),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Pending'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('All'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Approved'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _filteredBusinesses.isEmpty
              ? Center(
                  child: Text(
                    _filter == 'pending'
                        ? 'No pending businesses.'
                        : _filter == 'approved'
                        ? 'No approved businesses.'
                        : 'No businesses found.',
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = ResponsiveLayout.isMediumOrLarger(context);
                    final columns = ResponsiveLayout.adaptiveGridCount(
                      context,
                      compact: 1,
                      medium: 2,
                      expanded: 3,
                    );
                    if (!isDesktop) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredBusinesses.length,
                        itemBuilder: (context, index) =>
                            _buildBusinessCard(_filteredBusinesses[index], index),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredBusinesses.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.3,
                      ),
                      itemBuilder: (context, index) =>
                          _buildBusinessCard(_filteredBusinesses[index], index),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> item, int index) {
    final status = item['status'] ?? 'approved';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.teal, width: 1),
      ),
      child: ListTile(
        title: Text(item['name'] ?? 'Unnamed Business'),
        subtitle: Text(
          '${item['category'] ?? ''} • ${item['subcategory'] ?? ''}\nStatus: $status',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _setStatus(index, value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'approved', child: Text('Approve')),
            PopupMenuItem(value: 'rejected', child: Text('Reject')),
            PopupMenuItem(value: 'pending', child: Text('Set Pending')),
          ],
        ),
      ),
    );
  }
}
