import 'dart:io';
import 'package:findora/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:findora/screens/see_all_screen.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Map<String, dynamic>> allBusinesses = [];
  List<String> savedBusinessIds = [];
  String? _currentEmail;

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'subcategories': [], 'icon': Icons.apps},
    {
      'name': 'Food & Dining',
      'subcategories': ['Restaurants', 'Cafes', 'Bakeries', 'Hotels', 'Carts'],
      'icon': Icons.restaurant_menu,
    },
    {
      'name': 'Shopping',
      'subcategories': ['Clothing', 'Electronics', 'Grocery', 'Gifts'],
      'icon': Icons.shopping_bag,
    },
    {
      'name': 'Health & Beauty',
      'subcategories': ['Salons', 'Spas', 'Pharmacies', 'Clinics'],
      'icon': Icons.local_hospital,
    },
    {
      'name': 'Education',
      'subcategories': ['Schools', 'Colleges', 'Coaching Centers', 'Libraries'],
      'icon': Icons.school,
    },
    {
      'name': 'Services',
      'subcategories': [
        'Repair',
        'Laundry',
        'Delivery',
        'Photography',
        'Bank & Finance',
      ],
      'icon': Icons.miscellaneous_services,
    },
    {
      'name': 'Entertainment',
      'subcategories': ['Cinemas', 'Parks', 'Arcades', 'Events'],
      'icon': Icons.movie,
    },
    {
      'name': 'Online',
      'subcategories': [
        'E-Commerce & Retail',
        'Education & Training',
        'Digital & Freelance Services',
        'Marketing & Media',
        'Business & Professional Services',
      ],
      'icon': Icons.computer,
    },
  ];

  String selectedCategory = 'All';
  String? selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
    _loadSavedBusinesses();
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
      _currentEmail = email;
    });
  }

  Future<void> _loadBusinesses() async {
    final role = await AuthService().getCurrentUserRole();
    final email = await AuthService().getCurrentUserEmail();
    final businesses = await _storageService.getVisibleBusinesses(
      role: role,
      email: email,
    );
    setState(() {
      allBusinesses = businesses;
    });
  }

  Future<void> _loadSavedBusinesses() async {
    final savedIds = await _storageService.getSavedBusinesses();
    setState(() {
      savedBusinessIds = savedIds;
    });
  }

  Future<void> _toggleSave(
    String businessId,
    Map<String, dynamic> business,
  ) async {
    if (savedBusinessIds.contains(businessId)) {
      await _storageService.removeSavedBusiness(businessId);
      savedBusinessIds.remove(businessId);
      await AnalyticsService.logAction('unsave_business');
    } else {
      await _storageService.saveSavedBusiness(businessId);
      savedBusinessIds.add(businessId);
      await AnalyticsService.logAction('save_business');
    }

    setState(() {});
  }

  bool _isSaved(String businessId) {
    return savedBusinessIds.contains(businessId);
  }

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == 'All') return allBusinesses;

    return allBusinesses.where((item) {
      final matchesCategory = item['category'] == selectedCategory;
      final matchesSub = selectedSubcategory == null
          ? true
          : item['subcategory'] == selectedSubcategory;
      return matchesCategory && matchesSub;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 500 ? 500.0 : screenWidth;
    final scale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.3);

    final markers = allBusinesses
        .where((b) => b['latitude'] != null && b['longitude'] != null)
        .map(
          (b) => Marker(
            width: 40,
            height: 40,
            point: LatLng(
              (b['latitude'] as num).toDouble(),
              (b['longitude'] as num).toDouble(),
            ),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (_) => _buildBusinessDetails(b),
                );
              },
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: maxWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Top welcome + quick info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2D3F).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          color: Color(0xFF0A2D3F),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover nearby places',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A2D3F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Browse categories or tap on the map pins to explore businesses.',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// Map Section
                  SizedBox(
                    height: 230,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: const MapOptions(
                          initialCenter: LatLng(27.7052, 68.8570),
                          initialZoom: 12.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.findora.app',
                          ),
                          MarkerLayer(markers: markers),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// Section label: Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Browse by category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (allBusinesses.isNotEmpty)
                        Text(
                          '${filteredItems.length} places',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// Categories
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category['name'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = category['name'];
                              selectedSubcategory = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              // Use app-wide gradient for selected category, white for others
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF0A2D3F),
                                        const Color(
                                          0xFF0A2D3F,
                                        ).withOpacity(0.9),
                                        Colors.teal.shade700,
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Container(
                              width: 88,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 6,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    category['icon'] ?? Icons.category,
                                    size: 28,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF0A2D3F),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    category['name'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (selectedCategory != 'All') _buildSubcategories(),

                  const SizedBox(height: 16),

                  /// Heading + See All
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedCategory == 'All'
                              ? 'Explore All Places'
                              : selectedSubcategory == null
                              ? 'Explore $selectedCategory'
                              : 'Explore $selectedCategory → $selectedSubcategory',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllBusinessesScreen(
                                selectedCategory: selectedCategory,
                                selectedSubcategory: selectedSubcategory,
                                currentUserEmail: _currentEmail,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                        ),
                        child: const Text("See All"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// Grid of Businesses (responsive layout, original height)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;

                      // Responsive column count based on available width
                      int crossAxisCount;
                      if (maxWidth < 360) {
                        crossAxisCount = 1;
                      } else if (maxWidth < 600) {
                        crossAxisCount = 2;
                      } else {
                        crossAxisCount = 3;
                      }

                      // Make card content responsive to text scale
                      final textScale = MediaQuery.of(
                        context,
                      ).textScaleFactor.clamp(1.0, 1.4);

                      // Keep original fixed image height and base text height
                      const imageHeight = 120.0;
                      const baseTextSectionHeight = 80.0;
                      final cardMainAxisExtent =
                          imageHeight +
                          (baseTextSectionHeight * textScale) +
                          16;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          // Use a responsive main axis extent so content doesn't overflow
                          // or leave large empty space on different devices.
                          mainAxisExtent: cardMainAxisExtent,
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSaved = _isSaved(item['id']);

                          final hasCategory =
                              item['category'] != null &&
                              item['category'].isNotEmpty;
                          final hasSubcategory =
                              item['subcategory'] != null &&
                              item['subcategory'].isNotEmpty;

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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.teal.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.08),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Image with overlay, category pill and bookmark
                                  SizedBox(
                                    height: imageHeight,
                                    width: double.infinity,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                          child:
                                              item['image'] != null &&
                                                  item['image'].isNotEmpty
                                              ? (item['image'].startsWith(
                                                      'http',
                                                    )
                                                    ? Image.network(
                                                        item['image'],
                                                        width: double.infinity,
                                                        height: imageHeight,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(item['image']),
                                                        width: double.infinity,
                                                        height: imageHeight,
                                                        fit: BoxFit.cover,
                                                      ))
                                              : Container(
                                                  width: double.infinity,
                                                  height: imageHeight,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.storefront,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ),
                                        // subtle gradient at top for text/icons
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(
                                                      0.25,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // category pill + bookmark button
                                        Positioned(
                                          left: 8,
                                          right: 8,
                                          top: 8,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (hasCategory)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    color: Colors.white
                                                        .withOpacity(0.85),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.category_rounded,
                                                        size: 14,
                                                        color: Color(
                                                          0xFF0A2D3F,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        item['category'],
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Color(
                                                            0xFF0A2D3F,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    isSaved
                                                        ? Icons.bookmark
                                                        : Icons.bookmark_border,
                                                    color: isSaved
                                                        ? Colors.red
                                                        : const Color(
                                                            0xFF0A2D3F,
                                                          ),
                                                    size: 20,
                                                  ),
                                                  onPressed: () => _toggleSave(
                                                    item['id'],
                                                    item,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Text content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Unnamed',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Category + subcategory row
                                        if (hasCategory || hasSubcategory)
                                          Row(
                                            children: [
                                              if (hasCategory)
                                                Flexible(
                                                  child: Text(
                                                    item['category'],
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.teal,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              if (hasCategory && hasSubcategory)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                                  child: Text(
                                                    '•',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              if (hasSubcategory)
                                                Flexible(
                                                  child: Text(
                                                    item['subcategory'],
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

                                        const SizedBox(height: 4),

                                        // Address & timing row with icons
                                        if ((item['address'] != null &&
                                                item['address'].isNotEmpty) ||
                                            (item['timing'] != null &&
                                                item['timing'].isNotEmpty))
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (item['address'] != null &&
                                                  item['address'].isNotEmpty)
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.place_rounded,
                                                      size: 13,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        item['address'],
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (item['timing'] != null &&
                                                  item['timing'].isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons.schedule_rounded,
                                                        size: 13,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          item['timing'],
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessDetails(Map<String, dynamic> business) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business['name'] ?? 'Unnamed Business',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(business['category'] ?? 'No category'),
          const SizedBox(height: 8),
          Text(business['address'] ?? 'No address provided'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategories() {
    final selected =
        categories.firstWhere(
              (c) => c['name'] == selectedCategory,
            )['subcategories']
            as List;
    if (selected.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: selected.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sub = selected[index];
          final isSelected = selectedSubcategory == sub;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedSubcategory = sub;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1), // subtle shadow
                  ),
                ],
              ),
              child: Text(
                sub,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF0A2D3F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
