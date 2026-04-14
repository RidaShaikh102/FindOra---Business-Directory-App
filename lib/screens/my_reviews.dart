import 'package:flutter/material.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/analytics_service.dart';

class MyPostedReviewsScreen extends StatefulWidget {
  final String loggedInEmail;

  const MyPostedReviewsScreen({super.key, required this.loggedInEmail});

  @override
  State<MyPostedReviewsScreen> createState() => _MyPostedReviewsScreenState();
}

class _MyPostedReviewsScreenState extends State<MyPostedReviewsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Map<String, dynamic>> myReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
    AnalyticsService.logScreenView('MyReviewsScreen');
  }

  Future<void> _loadMyReviews() async {
    try {
      final allReviews = await _storageService.getReviews();
      setState(() {
        myReviews =
            allReviews
                .where((review) => review['userEmail'] == widget.loggedInEmail)
                .toList()
              ..sort(
                (a, b) =>
                    (b['timestamp'] as int).compareTo(a['timestamp'] as int),
              );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading reviews: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    await _storageService.deleteReview(reviewId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review deleted successfully")),
    );

    _loadMyReviews();
  }

  Future<void> _editReview(Map<String, dynamic> review) async {
    final TextEditingController reviewController = TextEditingController(
      text: review['reviewText'] ?? '',
    );
    double rating = (review['rating'] ?? 0).toDouble();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Review'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Business: ${review['businessName'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Your Review',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = Map<String, dynamic>.from(review);
              updated['reviewText'] = reviewController.text.trim();
              updated['rating'] = rating;
              updated['timestamp'] = DateTime.now().millisecondsSinceEpoch;
              await _storageService.saveReview(updated);

              Navigator.pop(context);
              _loadMyReviews();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Review updated successfully")),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final double rating = (review['rating'] ?? 0).toDouble();
    final String businessName = review['businessName'] ?? '';
    final String reviewText = review['reviewText'] ?? '';
    final String username = review['userName'] ?? '';
    final String userEmail = review['userEmail'] ?? '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.teal, width: 1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Edit/Delete buttons at top right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0A2D3F),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => _editReview(review),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReview(review['id']),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Email | Username
                Text(
                  '$userEmail | $username',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$reviewText"',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A2D3F),
                const Color(0xFF0A2D3F).withOpacity(0.9),
                Colors.teal.shade700,
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'My Posted Reviews',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : myReviews.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.reviews_outlined, size: 80, color: Colors.teal),
                  SizedBox(height: 16),
                  Text(
                    'You have not posted any reviews yet.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: myReviews.length,
              itemBuilder: (_, index) => _buildReviewCard(myReviews[index]),
            ),
    );
  }
}
