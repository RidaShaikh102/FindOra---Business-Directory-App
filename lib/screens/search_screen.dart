import 'package:findora/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/auth_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocalStorageService _storageService = LocalStorageService();
  List<Map<String, dynamic>> allBusinesses = [];
  List<Map<String, dynamic>> filteredBusinesses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    try {
      final role = await AuthService().getCurrentUserRole();
      final email = await AuthService().getCurrentUserEmail();
      final fetched = await _storageService.getVisibleBusinesses(
        role: role,
        email: email,
      );

      setState(() {
        allBusinesses = fetched;
        filteredBusinesses = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading businesses: $e");
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        filteredBusinesses = allBusinesses;
      } else {
        filteredBusinesses = allBusinesses.where((b) {
          final name = (b['name'] ?? '').toString().toLowerCase();
          final category = (b['category'] ?? '').toString().toLowerCase();
          final subcategory = (b['subcategory'] ?? '').toString().toLowerCase();
          final address = (b['address'] ?? '').toString().toLowerCase();

          return name.contains(keyword) ||
              category.contains(keyword) ||
              subcategory.contains(keyword) ||
              address.contains(keyword);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Search Businesses',
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.teal),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search by name, category, subcategory or location...',
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredBusinesses.isEmpty
                      ? const Center(
                          child: Text(
                            'No businesses found!',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredBusinesses.length,
                          itemBuilder: (context, index) {
                            final item = filteredBusinesses[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(item: item),
                                  ),
                                );
                              },
                              child: Card(
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Colors.teal,
                                    width: 0.5,
                                  ),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading:
                                      item['image'] != null &&
                                          item['image'].toString().isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            item['image'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.storefront,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                  title: Text(
                                    item['name'] ?? 'Unnamed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item['category'] ?? ''} → ${item['subcategory'] ?? ''}\n${item['address'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  isThreeLine: true,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
