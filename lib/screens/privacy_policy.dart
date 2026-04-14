import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🟢 Header section same as Help Center
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2D3F),
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

            const SizedBox(height: 20),

            // 📘 Intro Paragraph
            Text(
              "Your privacy is important to us. This Privacy Policy explains how FindOra collects, uses, and protects your personal information.",
              style: TextStyle(
                fontSize: 15 * scale,
                color: Colors.black87,
                height: 1.6,
              ),
              textAlign: TextAlign.start,
            ),

            const SizedBox(height: 20),

            // 🔽 Privacy Sections (Same style as FAQ in Help Center)
            _buildExpansion(
              "1. Information We Collect",
              "We collect user details (name, email, phone), business interactions, and technical device information.",
              scale,
            ),

            _buildExpansion(
              "2. How We Use Your Information",
              "We use collected data to improve services, personalize results, secure your account, and enhance your app experience.",
              scale,
            ),

            _buildExpansion(
              "3. Sharing of Information",
              "We do not sell your personal data. Information may be shared with trusted services like Google Maps.",
              scale,
            ),

            _buildExpansion(
              "4. Data Security",
              "We use secure technologies and internal policies to protect your personal data.",
              scale,
            ),

            _buildExpansion(
              "5. Your Choices",
              "You may review, update, or request deletion of your data at any time.",
              scale,
            ),

            _buildExpansion(
              "6. Third-Party Services",
              "Some features rely on trusted partners like Google Maps or Web3Forms.",
              scale,
            ),

            _buildExpansion(
              "7. Changes to This Policy",
              "We may update our Privacy Policy over time. Changes will be announced inside the app.",
              scale,
            ),

            _buildExpansion(
              "8. Contact Us",
              "For privacy concerns, business inquiries, or account issues, contact us at your provided support email.",
              scale,
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
        iconColor: Colors.teal,
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
