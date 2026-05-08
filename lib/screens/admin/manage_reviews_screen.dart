import 'package:flutter/material.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/analytics_service.dart';

class ManageReviewsScreen extends StatefulWidget {
  const ManageReviewsScreen({super.key});

  @override
  State<ManageReviewsScreen> createState() => _ManageReviewsScreenState();
}

class _ManageReviewsScreenState extends State<ManageReviewsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await _storageService.getReviews(includeHidden: true);
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to load reviews right now. Pull down or tap retry.';
      });
    }
  }

  Future<void> _toggleHidden(int index) async {
    final updated = Map<String, dynamic>.from(_reviews[index]);
    updated['hidden'] = !(updated['hidden'] == true);
    _reviews[index] = updated;
    await _storageService.saveReview(updated);
    await AnalyticsService.logAction(
      updated['hidden'] == true ? 'review_hidden' : 'review_unhidden',
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteReview(int index) async {
    final reviewId = _reviews[index]['id']?.toString();
    _reviews.removeAt(index);
    if (reviewId != null && reviewId.isNotEmpty) {
      await _storageService.deleteReview(reviewId);
    }
    await AnalyticsService.logAction('review_deleted');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadReviews,
        color: Colors.teal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 320,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadReviews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReviews,
        color: Colors.teal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 320, child: Center(child: Text('No reviews found.'))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: Colors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          final hidden = review['hidden'] == true;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.teal, width: 1),
            ),
            child: ListTile(
              title: Text(review['businessName'] ?? 'Business'),
              subtitle: Text(
                '${review['userEmail'] ?? ''}\n${review['reviewText'] ?? ''}\nRating: ${review['rating'] ?? 0}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'toggle') {
                    _toggleHidden(index);
                  } else if (value == 'delete') {
                    _deleteReview(index);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(hidden ? 'Unhide' : 'Hide'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
