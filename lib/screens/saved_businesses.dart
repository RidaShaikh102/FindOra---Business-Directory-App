import 'package:findora/screens/detail_screen.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/widgets/business_card.dart';

class SavedBusinessesScreen extends StatefulWidget {
  const SavedBusinessesScreen({super.key});

  @override
  State<SavedBusinessesScreen> createState() => _SavedBusinessesScreenState();
}

class _SavedBusinessesScreenState extends State<SavedBusinessesScreen> {
  List<Map<String, dynamic>> allBusinesses = [];
  List<String> savedIds = [];
  bool isLoading = true;
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadSavedBusinesses();
  }

  Future<void> _loadSavedBusinesses() async {
    try {
      savedIds = await _storageService.getSavedBusinesses();
      final role = await AuthService().getCurrentUserRole();
      final email = await AuthService().getCurrentUserEmail();
      allBusinesses = await _storageService.getVisibleBusinesses(
        role: role,
        email: email,
      );

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error loading saved businesses: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Mobile layout only (≤ 500px)
    if (screenWidth > 500) {
      return Scaffold(
        body: Center(
          child: Text(
            "This screen is only available on mobile devices.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ),
      );
    }

    final savedBusinesses = allBusinesses
        .where((b) => savedIds.contains(b['id']))
        .toList();
    final scale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.teal),
        title: Text(
          "Saved Businesses",
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : savedBusinesses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.teal.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No saved businesses yet!",
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: savedBusinesses.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.74,
                ),
                itemBuilder: (context, index) {
                  final item = savedBusinesses[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(item: item),
                        ),
                      );
                    },
                    child: BusinessCard(item: item),
                  );
                },
              ),
            ),
    );
  }
}
