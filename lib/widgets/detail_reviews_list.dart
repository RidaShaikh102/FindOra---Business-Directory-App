import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../services/local_storage_service.dart';

class DetailReviewsList extends StatefulWidget {
  final String businessId;
  final double averageRating;
  final VoidCallback? onSeeAll;

  const DetailReviewsList({
    super.key,
    required this.businessId,
    required this.averageRating,
    this.onSeeAll,
  });

  @override
  State<DetailReviewsList> createState() => _DetailReviewsListState();
}

class _DetailReviewsListState extends State<DetailReviewsList> {
  static const _pageSize = 10;

  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    debugPrint('DetailReviewsList init for businessId: ${widget.businessId}');
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      debugPrint(
        'Fetching reviews for business: ${widget.businessId}, pageKey: $pageKey',
      );

      // Only check for last page if we have items and this isn't the first page
      final hasNoItems = _pagingController.itemList?.isEmpty ?? true;
      if (hasNoItems && pageKey > 0) {
        _pagingController.appendLastPage([]);
        return;
      }

      final lastTimestamp = _pagingController.itemList?.isNotEmpty == true
          ? _pagingController.itemList!.last['timestamp'] as int
          : null;

      final newItems = await LocalStorageService().getReviewPageByBusiness(
        widget.businessId,
        startAfter: lastTimestamp,
        limit: _pageSize,
      );
      debugPrint(
        'Fetched ${newItems.length} reviews for business: ${widget.businessId}',
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      debugPrint('Error fetching reviews: $error');
      _pagingController.error = error;
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final name = review['userName'] ?? 'Anonymous';
    final reviewText = review['reviewText'] ?? 'No review text';
    final ratingValue = review['rating'] ?? 0;

    double rating = 0.0;
    if (ratingValue is double) {
      rating = ratingValue;
    } else if (ratingValue is int) {
      rating = ratingValue.toDouble();
    } else if (ratingValue is String) {
      rating = double.tryParse(ratingValue) ?? 0.0;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.teal, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline, size: 28, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < rating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"$reviewText"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedListView<int, Map<String, dynamic>>.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
            noItemsFoundIndicatorBuilder: (context) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "No reviews yet.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            firstPageErrorIndicatorBuilder: (context) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load reviews: ${_pagingController.error.toString().split(':').last.trim()}',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _pagingController.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            newPageErrorIndicatorBuilder: (context) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load more reviews: ${_pagingController.error.toString().split(':').last.trim()}',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _pagingController.retryLastFailedRequest(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            itemBuilder: (context, item, index) => _buildReviewCard(item),
          ),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
        if (widget.onSeeAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onSeeAll,
              child: const Text(
                "See All",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
