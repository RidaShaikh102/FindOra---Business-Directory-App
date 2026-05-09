import 'package:findora/screens/detail_screen.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/widgets/business_card.dart';
import 'package:findora/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';

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
      debugPrint('Error loading saved businesses: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleSave(Map<String, dynamic> item) async {
    final businessId = item['id']?.toString() ?? '';
    if (businessId.isEmpty) return;

    if (savedIds.contains(businessId)) {
      await _storageService.removeSavedBusiness(businessId);
      savedIds.remove(businessId);
    } else {
      await _storageService.saveSavedBusiness(businessId);
      savedIds.add(businessId);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedBusinesses = allBusinesses
        .where((b) => savedIds.contains(b['id']))
        .toList();
    final emptyStateFontSize = MediaQuery.textScalerOf(context).scale(16);
    final columns = ResponsiveLayout.adaptiveGridCount(
      context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.teal),
        title: const Text(
          'Saved Businesses',
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ResponsivePageContainer(
          maxWidth: 1200,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
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
                        'No saved businesses yet!',
                        style: TextStyle(
                          fontSize: emptyStateFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final useComfortableCards = columns >= 3;
                      const gridSpacing = 12.0;
                      final cardWidth =
                          (constraints.maxWidth -
                              (gridSpacing * (columns - 1))) /
                          columns;
                      final cardHeight = BusinessCard.recommendedMainAxisExtent(
                        cardWidth,
                        textScale: textScale,
                        comfortable: useComfortableCards,
                      );

                      return GridView.builder(
                        itemCount: savedBusinesses.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: gridSpacing,
                          mainAxisSpacing: gridSpacing,
                          mainAxisExtent: cardHeight,
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
                            child: BusinessCard(
                              item: item,
                              showSaveButton: true,
                              isSaved: true,
                              onSave: () => _toggleSave(item),
                              borderRadius: BorderRadius.circular(22),
                              useComfortableDensity: useComfortableCards,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
