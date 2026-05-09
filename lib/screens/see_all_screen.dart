import 'package:findora/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/widgets/business_card.dart';
import 'package:findora/widgets/responsive_layout.dart';

class AllBusinessesScreen extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedSubcategory;
  final String? currentUserEmail;

  const AllBusinessesScreen({
    super.key,
    this.selectedCategory,
    this.selectedSubcategory,
    this.currentUserEmail,
  });

  @override
  State<AllBusinessesScreen> createState() => _AllBusinessesScreenState();
}

class _AllBusinessesScreenState extends State<AllBusinessesScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  String? _currentUserEmail;

  List<Map<String, dynamic>> allBusinesses = [];
  List<Map<String, dynamic>> filteredBusinesses = [];
  String searchQuery = '';
  Set<String> savedBusinessIds = {};
  bool isLoading = false;

  // Filter & sort variables
  String? filterCategory;
  String? filterSubcategory;
  String? sortOption;

  @override
  void initState() {
    super.initState();
    filterCategory = widget.selectedCategory;
    filterSubcategory = widget.selectedSubcategory;
    _loadBusinesses();
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh saved businesses when returning to this screen
    _loadSavedBusinesses();
  }

  Future<void> _loadCurrentUser() async {
    final email = await AuthService().getCurrentUserEmail();
    setState(() {
      _currentUserEmail = email;
    });
    // After loading user, load saved businesses
    _loadSavedBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => isLoading = true);
    try {
      final role = await AuthService().getCurrentUserRole();
      final email = await AuthService().getCurrentUserEmail();
      final businesses = await _storageService.getVisibleBusinesses(
        role: role,
        email: email,
      );

      setState(() {
        allBusinesses = businesses;
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading businesses: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadSavedBusinesses() async {
    try {
      final savedIds = await _storageService.getSavedBusinesses();
      setState(() {
        savedBusinessIds = savedIds.toSet();
      });
    } catch (e) {
      debugPrint('Error loading saved businesses: $e');
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> tempList = allBusinesses.where((b) {
      final matchesCategory =
          filterCategory == null ||
          filterCategory == 'All' ||
          b['category'] == filterCategory;
      final matchesSubcategory =
          filterSubcategory == null || b['subcategory'] == filterSubcategory;

      final query = searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty
          ? true
          : (b['name']?.toLowerCase().contains(query) ?? false) ||
                (b['category']?.toLowerCase().contains(query) ?? false) ||
                (b['subcategory']?.toLowerCase().contains(query) ?? false) ||
                (b['address']?.toLowerCase().contains(query) ?? false);

      return matchesCategory && matchesSubcategory && matchesSearch;
    }).toList();

    // Sorting
    if (sortOption == 'asc') {
      tempList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (sortOption == 'desc') {
      tempList.sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
    } else if (sortOption == 'location') {
      tempList.sort(
        (a, b) => (a['address'] ?? '').compareTo(b['address'] ?? ''),
      );
    }

    setState(() {
      filteredBusinesses = tempList;
    });
  }

  Future<void> _toggleSave(Map<String, dynamic> item) async {
    if (_currentUserEmail == null || _currentUserEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save businesses.")),
      );
      return;
    }

    final businessId = item['id'];

    setState(() {
      if (savedBusinessIds.contains(businessId)) {
        savedBusinessIds.remove(businessId);
        _storageService.removeSavedBusiness(businessId);
        AnalyticsService.logAction('unsave_business');
      } else {
        savedBusinessIds.add(businessId);
        _storageService.saveSavedBusiness(businessId);
        AnalyticsService.logAction('save_business');
      }
    });
  }

  void _openFilterDialog() {
    final categoryController = TextEditingController(
      text: filterCategory ?? '',
    );
    final subcategoryController = TextEditingController(
      text: filterSubcategory ?? '',
    );
    String? tempSort = sortOption;

    showDialog(
      context: context,
      builder: (_) {
        return Center(
          child: ResponsivePageContainer(
            maxWidth: 720,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sort by',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RadioListTile(
                          title: const Text('Ascending (Name)'),
                          value: 'asc',
                          groupValue: tempSort,
                          onChanged: (val) =>
                              setStateDialog(() => tempSort = val),
                        ),
                        RadioListTile(
                          title: const Text('Descending (Name)'),
                          value: 'desc',
                          groupValue: tempSort,
                          onChanged: (val) =>
                              setStateDialog(() => tempSort = val),
                        ),
                        RadioListTile(
                          title: const Text('By Location (Address)'),
                          value: 'location',
                          groupValue: tempSort,
                          onChanged: (val) =>
                              setStateDialog(() => tempSort = val),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        TextField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.category,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: subcategoryController,
                          decoration: const InputDecoration(
                            labelText: 'Subcategory',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.subdirectory_arrow_right,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  filterCategory = null;
                                  filterSubcategory = null;
                                  sortOption = null;
                                  _applyFilters();
                                });
                              },
                              child: const Text('See All'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  filterCategory =
                                      categoryController.text.isEmpty
                                      ? null
                                      : categoryController.text;
                                  filterSubcategory =
                                      subcategoryController.text.isEmpty
                                      ? null
                                      : subcategoryController.text;
                                  sortOption = tempSort;
                                  _applyFilters();
                                });
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyBgColor = Colors.grey[200];

    return Scaffold(
      backgroundColor: bodyBgColor,
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
        title: const Text(
          'All Businesses',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ResponsivePageContainer(
          maxWidth: 1280,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          searchQuery = val;
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search by name, category, subcategory, or location',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.teal,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
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
                    const SizedBox(width: 8),
                    // Filter button
                    ElevatedButton(
                      onPressed: _openFilterDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      child: const Icon(Icons.filter_list, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        )
                      : filteredBusinesses.isEmpty
                      ? const Center(child: Text('No businesses found.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = ResponsiveLayout.adaptiveGridCount(
                              context,
                              compact: 2,
                              medium: 3,
                              expanded: 4,
                            );
                            final textScale = MediaQuery.textScalerOf(
                              context,
                            ).scale(1);
                            final useComfortableCards = columns >= 3;
                            const gridSpacing = 10.0;
                            final cardWidth =
                                (constraints.maxWidth -
                                    (gridSpacing * (columns - 1))) /
                                columns;
                            final cardHeight =
                                BusinessCard.recommendedMainAxisExtent(
                                  cardWidth,
                                  textScale: textScale,
                                  comfortable: useComfortableCards,
                                );
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: gridSpacing,
                                    mainAxisSpacing: gridSpacing,
                                    mainAxisExtent: cardHeight,
                                  ),
                              itemCount: filteredBusinesses.length,
                              itemBuilder: (context, index) {
                                final item = filteredBusinesses[index];
                                final isSaved = savedBusinessIds.contains(
                                  item['id'],
                                );

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetailScreen(item: item),
                                      ),
                                    );
                                  },
                                  child: BusinessCard(
                                    item: item,
                                    showSaveButton: true,
                                    isSaved: isSaved,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
