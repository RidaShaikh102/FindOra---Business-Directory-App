import 'package:flutter/material.dart';
import 'package:findora/widgets/responsive_layout.dart';

class SharedProfileScreen extends StatelessWidget {
  final String username;
  final String role;
  final String city;

  const SharedProfileScreen({
    super.key,
    required this.username,
    required this.role,
    required this.city,
  });

  String _roleLabel(String value) {
    if (value.trim().isEmpty) return 'FindOra user';
    return value.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Shared Profile'),
        backgroundColor: const Color(0xFF0A2D3F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ResponsivePageContainer(
          maxWidth: 980,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(
                      Icons.person,
                      size: 44,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username.trim().isEmpty ? 'FindOra User' : username,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleLabel(role),
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (city.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      city,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Discover local businesses with FindOra.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
