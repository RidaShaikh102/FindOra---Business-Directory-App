import 'package:findora/services/auth_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/utils/logger.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({super.key});

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  final LocalStorageService _storageService = LocalStorageService();

  List<Map<String, dynamic>> userBusinesses = [];
  Map<String, List<Map<String, dynamic>>> businessReviews = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    AnalyticsService.logScreenView('UserReviewsScreen');
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);
      AppLogger.i('🔍 UserReviewsScreen - Loading user data/reviews');

      final authService = AuthService();
      final loggedIn = await authService.isLoggedIn();
      if (!loggedIn) {
        AppLogger.w('User not logged in');
        setState(() => _isLoading = false);
        return;
      }

      final loggedInEmail = await authService.getCurrentUserEmail();
      if (loggedInEmail == null) {
        AppLogger.w('No email found');
        setState(() => _isLoading = false);
        return;
      }

      AppLogger.i('Loading businesses for owner: $loggedInEmail');
      userBusinesses = await _storageService.getBusinessesByOwner(
        loggedInEmail,
      );
      AppLogger.i('Found ${userBusinesses.length} businesses for user');

      AppLogger.i('Loading reviews for owner businesses');
      final allReviews = await _storageService.getReviewsByOwnerEmail(
        loggedInEmail,
      );

      // Group reviews by business name
      businessReviews.clear();
      for (var business in userBusinesses) {
        final businessName = business['name'] ?? 'Unnamed Business';
        businessReviews[businessName] = allReviews
            .where((r) => r['businessName'] == businessName)
            .toList();
      }

      AppLogger.i('✅ UserReviewsScreen load complete');
    } catch (e) {
      AppLogger.e('❌ UserReviewsScreen _loadReviews ERROR: $e', e);
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Reviews")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReviews,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : userBusinesses.isEmpty
          ? const Center(child: Text("No businesses or reviews found."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: userBusinesses.length,
              itemBuilder: (context, index) {
                final business = userBusinesses[index];
                final businessName = business['name'] ?? 'Unnamed';
                final reviews = businessReviews[businessName] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviews for "$businessName"',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (reviews.isEmpty)
                      const Text(
                        "No reviews yet.",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...reviews.map((review) {
                        final name = review['userName'] ?? 'Anonymous';
                        final rating = (review['rating'] ?? 0).toDouble();
                        final reviewText = review['reviewText'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Colors.teal,
                              width: 0.6,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 28,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            index < rating.round()
                                                ? Icons.star
                                                : Icons.star_border,
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
                      }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }
}
