import 'package:flutter/material.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/analytics_service.dart';

class ManageClaimsScreen extends StatefulWidget {
  const ManageClaimsScreen({super.key});

  @override
  State<ManageClaimsScreen> createState() => _ManageClaimsScreenState();
}

class _ManageClaimsScreenState extends State<ManageClaimsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Map<String, dynamic>> _claims = [];
  bool _loading = true;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    final list = await _storageService.getClaims();
    setState(() {
      _claims = list;
      _loading = false;
    });
  }

  Future<void> _setClaimStatus(String claimId, String status) async {
    if (claimId.isEmpty) return;

    if (status == 'approved') {
      await _storageService.approveClaim(claimId);
      await AnalyticsService.logAction('claim_approved');
    } else {
      await _storageService.updateClaimStatus(claimId, status);
      await AnalyticsService.logAction('claim_${status}');
    }

    await _loadClaims();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    final visibleClaims = _filter == 'all'
        ? _claims
        : _claims.where((item) {
            final status = (item['status'] ?? 'pending').toString();
            return status == _filter;
          }).toList();

    if (visibleClaims.isEmpty) {
      return const Center(
        child: Text('No claims found for the selected filter.'),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        ToggleButtons(
          isSelected: [
            _filter == 'pending',
            _filter == 'approved',
            _filter == 'cancelled',
            _filter == 'all',
          ],
          onPressed: (index) {
            setState(() {
              if (index == 0) {
                _filter = 'pending';
              } else if (index == 1) {
                _filter = 'approved';
              } else if (index == 2) {
                _filter = 'cancelled';
              } else {
                _filter = 'all';
              }
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
              child: Text('Approved'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Cancelled'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visibleClaims.length,
            itemBuilder: (context, index) {
              final claim = visibleClaims[index];
              final status = (claim['status'] ?? 'pending').toString();
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.teal, width: 1),
                ),
                child: ListTile(
                  title: Text(claim['name'] ?? 'Unknown claimant'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Business ID: ${claim['businessId'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text('User ID: ${claim['userId'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text('Phone: ${claim['phone'] ?? 'N/A'}'),
                      if ((claim['message'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Message: ${claim['message']}'),
                      ],
                      const SizedBox(height: 4),
                      Text('Status: ${status.toUpperCase()}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        _setClaimStatus(claim['id']?.toString() ?? '', value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'approved',
                        child: Text('Approve'),
                      ),
                      const PopupMenuItem(
                        value: 'cancelled',
                        child: Text('Cancel'),
                      ),
                      const PopupMenuItem(
                        value: 'pending',
                        child: Text('Set Pending'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
