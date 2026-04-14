import 'package:flutter/material.dart';
import 'package:findora/services/analytics_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('HelpCenterScreen');
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;

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
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Help Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 🟢 Top full-width rounded container with logo and FindOra text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Color(0xFF0A2D3F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Image.asset('lib/assets/logo.png', width: 150, height: 150),
                  const SizedBox(height: 5),
                  Text(
                    'FindOra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: scale * 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// 📘 Intro Paragraph
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Welcome to the FindOra Help Center!\n\n"
                "We’re here to make your experience smooth, simple, and enjoyable. "
                "If you ever get stuck or have a question, you’ll likely find the answer below.",
                style: TextStyle(
                  fontSize: 15 * scale,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔽 FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildExpansion(
                    "1. What is FindOra?",
                    "FindOra is a local discovery platform that helps users find nearby businesses, restaurants, hospitals, and services in Sukkur and beyond.",
                    scale,
                  ),
                  _buildExpansion(
                    "2. How can I list my business on FindOra?",
                    "You can submit your business details through the 'Add Business' option or contact our support team for verification.",
                    scale,
                  ),
                  _buildExpansion(
                    "3. How does the search work?",
                    "Our search allows users to find businesses by category, subcategory, and location, offering accurate real-time results.",
                    scale,
                  ),
                  _buildExpansion(
                    "4. Is FindOra free to use?",
                    "Yes! FindOra is completely free for users. Business listings may have optional premium features in the future.",
                    scale,
                  ),
                  _buildExpansion(
                    "5. Can I post reviews?",
                    "Yes. Registered users can post reviews and ratings for businesses they’ve visited or interacted with.",
                    scale,
                  ),
                  _buildExpansion(
                    "6. How do I reset my password?",
                    "You can reset your password from the login screen by selecting 'Forgot Password' and following the steps sent to your email.",
                    scale,
                  ),
                  _buildExpansion(
                    "7. How can I contact support?",
                    "Go to the Contact Us section of the app, fill out the form, and our team will get back to you as soon as possible.",
                    scale,
                  ),
                  _buildExpansion(
                    "8. How do I update my profile?",
                    "Open your Profile section and tap 'Edit Profile' to change your name, email, or profile picture.",
                    scale,
                  ),
                  _buildExpansion(
                    "9. Why can't I see certain listings?",
                    "Some listings may be hidden or pending verification. Please refresh your app or contact support if the issue continues.",
                    scale,
                  ),
                  _buildExpansion(
                    "10. How often is the data updated?",
                    "Our team regularly updates listings to ensure accuracy. Business owners can also update their information directly.",
                    scale,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansion(String title, String content, double scale) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: Colors.teal, // Teal instead of blue
        collapsedIconColor: Colors.grey,
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16 * scale),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              content,
              style: TextStyle(fontSize: 14 * scale, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
