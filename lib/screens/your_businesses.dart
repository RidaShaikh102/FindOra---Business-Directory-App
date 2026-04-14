import 'package:findora/screens/add_business_screen.dart';
import 'package:findora/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/services/local_storage_service.dart';

class YourBusinessesScreen extends StatefulWidget {
  final String userEmail;

  const YourBusinessesScreen({super.key, required this.userEmail});

  @override
  State<YourBusinessesScreen> createState() => _YourBusinessesScreenState();
}

class _YourBusinessesScreenState extends State<YourBusinessesScreen> {
  List<Map<String, dynamic>> userBusinesses = [];
  String loggedInEmail = "";
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    loggedInEmail = widget.userEmail;
    _loadUserBusinesses();
    AnalyticsService.logScreenView('YourBusinessesScreen');
  }

  Future<void> _loadUserBusinesses() async {
    try {
      final businesses = await _storageService.getBusinesses();
      setState(() {
        userBusinesses = businesses
            .where((b) => b['ownerEmail'] == loggedInEmail)
            .toList();
      });
    } catch (e) {
      debugPrint("Error loading user businesses: $e");
    }
  }

  Future<void> _deleteBusiness(int index) async {
    final businessId = userBusinesses[index]['id']?.toString();
    setState(() {
      userBusinesses.removeAt(index);
    });
    if (businessId != null && businessId.isNotEmpty) {
      await _storageService.deleteBusiness(businessId);
    }
  }

  Future<void> _editBusiness(int index) async {
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddBusinessScreen(existingBusiness: userBusinesses[index]),
      ),
    );

    _loadUserBusinesses();
  }

  Future<void> _addBusiness() async {
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddBusinessScreen()),
    );

    _loadUserBusinesses();
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Businesses",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userBusinesses.isEmpty
          ? const Center(child: Text("No businesses added yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: userBusinesses.length,
              itemBuilder: (context, index) {
                final item = userBusinesses[index];
                final rating = item['rating'] ?? 0.0;

                return Card(
                  color: bodyColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.teal, width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(item: item),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                item['image'] != null &&
                                    item['image'].isNotEmpty
                                ? Image.network(
                                    item['image'],
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 110,
                                    height: 110,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.storefront,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Business Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item['name'] ?? 'Unnamed',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${item['category'] ?? ''} → ${item['subcategory'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['timing'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['address'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(rating.toString()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Edit/Delete Menu
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editBusiness(index);
                              } else if (value == 'delete') {
                                _deleteBusiness(index);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _addBusiness,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
