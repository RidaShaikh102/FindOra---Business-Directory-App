import 'package:findora/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/widgets/error_boundary.dart';

class WriteReviewScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String userEmail;

  const WriteReviewScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.userEmail,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _reviewController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  double rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userEmail.split('@')[0];
    _emailController.text = widget.userEmail;
    AnalyticsService.logScreenView('WriteReviewScreen');
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please write your review")));
      return;
    }

    if (rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a rating")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final localStorage = LocalStorageService();
      final business =
          await localStorage.getBusinessById(widget.businessId) ??
          <String, dynamic>{};
      final ownerEmail = business['ownerEmail'] ?? '';
      final reviewData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userName': _nameController.text.trim(),
        'userEmail': _emailController.text.trim(),
        'businessName': widget.businessName,
        'businessId': widget.businessId,
        'businessOwnerEmail': ownerEmail,
        'reviewText': _reviewController.text.trim(),
        'rating': rating,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'hidden': false,
      };

      await localStorage.saveReview(reviewData);
      await AnalyticsService.logAction('add_review');
      await AnalyticsService.logReviewWritten(
        widget.businessId,
        businessName: widget.businessName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.teal, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.teal, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.teal, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      screenName: 'WriteReviewScreen',
      builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Write a Review",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.businessName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Business Name (read-only)
                      TextField(
                        controller: TextEditingController(
                          text: widget.businessName,
                        ),
                        decoration: _inputDecoration("Business Name"),
                        readOnly: true,
                      ),
                      const SizedBox(height: 15),

                      // User Name
                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration("Your Name"),
                      ),
                      const SizedBox(height: 15),

                      // User Email
                      TextField(
                        controller: _emailController,
                        decoration: _inputDecoration("Your Email"),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),

                      // Review Text
                      TextField(
                        controller: _reviewController,
                        decoration: _inputDecoration("Your Review"),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 15),

                      // Rating Stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 30,
                            ),
                            onPressed: () {
                              setState(() {
                                rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 25),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 50,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Submit Review",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
