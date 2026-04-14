import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const tealColor = Color(0xFF008080);
    const darkContainerColor = Color(0xFF0A2D3F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'About FindOra',
          style: theme.textTheme.titleLarge?.copyWith(color: tealColor),
        ),
        iconTheme: const IconThemeData(color: tealColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Logo + App Name container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: darkContainerColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Image.asset('lib/assets/logo.png', width: 120, height: 120),
                  const SizedBox(height: 12),
                  Text(
                    'FindOra',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            _buildCard(
              context: context,
              title: 'About FindOra',
              content:
                  'FindOra is your digital companion for discovering local businesses, services, and attractions in your area. Our goal is to make it easy for you to find restaurants, shops, healthcare services, educational institutions, entertainment spots, and much more.',
              borderColor: tealColor,
            ),
            const SizedBox(height: 16),

            // Key Features Section
            _buildCard(
              context: context,
              title: 'Key Features',
              content:
                  '• Browse and search local businesses by category and location\n'
                  '• Save your favorite businesses for quick access\n'
                  '• Get detailed information including address, timings, and contact info\n'
                  '• Contact businesses or reach out to us directly from the app\n'
                  '• Explore your city with our curated suggestions and recommendations',
              borderColor: tealColor,
            ),
            const SizedBox(height: 16),

            // Mission Section
            _buildCard(
              context: context,
              title: 'Our Mission',
              content:
                  'At FindOra, our mission is to empower users to easily discover and engage with local businesses, helping both customers and business owners thrive in the digital era.',
              borderColor: tealColor,
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                '© 2025 FindOra. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String content,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
