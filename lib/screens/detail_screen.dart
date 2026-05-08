import 'package:findora/screens/review_screen.dart';
import 'package:findora/widgets/detail_reviews_list.dart';
import 'package:findora/widgets/detail_map_widget.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findora/services/auth_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/screens/all_reviews_screen.dart';
import 'package:findora/screens/claim_business_screen.dart';
import 'package:findora/screens/services_screen.dart';
import 'package:findora/screens/signup_screen.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/widgets/detail_hero_image.dart';
import 'package:findora/widgets/detail_quick_actions.dart';
import 'package:findora/widgets/error_boundary.dart';
import 'package:findora/services/deep_link_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:findora/widgets/lottie_helper.dart';
import '../utils/logger.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final AuthService _authService = AuthService();
  final LocalStorageService _storageService = LocalStorageService();
  String _currentEmail = '';
  String _currentUserRole = 'user';
  bool _isSaved = false;
  Timer? _debounce;
  bool _isLoadingCall = false;
  bool _isLoadingWhatsApp = false;
  bool _isLoadingLocate = false;
  bool _isLoadingWebsite = false;
  bool _isDataLoading = true;
  String? _dataError;

  // All vars initialized directly
  late final String image;
  late final String name;
  late final String address;
  late final String contact;
  late final String whatsapp;
  late final String website;
  late final String liveLocation;
  late final String subcategory;
  late final String timing;
  late final String description;
  late final String category;
  late final String ownerEmail;
  late final String instagram;
  late final String facebook;
  late final double? latitude;
  late final double? longitude;

  double? _cachedAverageRating;

  double get averageRating {
    return _cachedAverageRating ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    image = widget.item['image'] ?? '';
    name = widget.item['name'] ?? 'Unnamed Place';
    address = widget.item['address'] ?? 'Address not available';
    contact = widget.item['contact'] ?? '';
    whatsapp = widget.item['whatsapp'] ?? '';
    website = widget.item['website'] ?? '';
    liveLocation = widget.item['liveLocation'] ?? '';
    subcategory = widget.item['subcategory']?.toString() ?? 'General';
    timing = widget.item['timing']?.toString() ?? 'Timings not available';
    description = widget.item['description'] ?? 'No description available.';
    category = widget.item['category'] ?? 'Services';
    ownerEmail = widget.item['ownerEmail'] ?? '';
    instagram = widget.item['instagram'] ?? '';
    facebook = widget.item['facebook'] ?? '';
    latitude = widget.item['latitude'];
    longitude = widget.item['longitude'];
    _initializeData();
    AnalyticsService.logScreenView('DetailScreen');
    AnalyticsService.logBusinessViewed(
      widget.item['id'] ?? '',
      businessName: name,
    );
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _loadCurrentUser(),
        _loadCurrentUserRole(),
        _loadSavedStatus(),
        _loadAverageRating(),
      ]);
    } catch (e) {
      _dataError = e.toString();
      AppLogger.e('DetailScreen data load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isDataLoading = false);
      }
    }
  }

  Future<void> _loadSavedStatus() async {
    final savedIds = await _storageService.getSavedBusinesses();
    if (mounted) {
      setState(() {
        _isSaved = savedIds.contains(widget.item['id']);
      });
    }
  }

  void _onToggleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _toggleSaveImpl);
  }

  Future<void> _toggleSaveImpl() async {
    final businessId = widget.item['id'];
    if (businessId == null || businessId.isEmpty) return;

    if (_isSaved) {
      await _storageService.removeSavedBusiness(businessId);
      await AnalyticsService.logAction('unsave_business');
    } else {
      await _storageService.saveSavedBusiness(businessId);
      await AnalyticsService.logAction('save_business');
    }

    if (mounted) {
      setState(() {
        _isSaved = !_isSaved;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final email = await _authService.getCurrentUserEmail();
    if (mounted) {
      setState(() => _currentEmail = email ?? '');
    }
  }

  Future<void> _loadCurrentUserRole() async {
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() => _currentUserRole = role ?? 'user');
    }
  }

  Future<void> _handleClaimTap() async {
    if (widget.item['ownerId'] != null) return;

    // If current user is admin, allow direct claiming
    if (_currentEmail == 'admin@findora.cok') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClaimBusinessScreen(
            businessId: widget.item['id']?.toString() ?? '',
          ),
        ),
      );
      return;
    }

    // If current user is already an owner, allow claiming
    if (_currentUserRole == 'owner') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClaimBusinessScreen(
            businessId: widget.item['id']?.toString() ?? '',
          ),
        ),
      );
      return;
    }

    // Otherwise, prompt to become an owner
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Become a Business Owner'),
          content: const Text(
            'To claim this business, you need to create an owner account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create Owner Account'),
            ),
          ],
        );
      },
    );

    if (shouldCreate == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignUpScreen()),
      );
    }
  }

  Future<void> _loadAverageRating() async {
    try {
      final average = await _storageService.getAverageRatingForBusiness(
        widget.item['id'] ?? '',
      );
      if (mounted) {
        setState(() => _cachedAverageRating = average);
      }
    } catch (e) {
      AppLogger.e('Error loading average rating: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (url.startsWith('http://')) {
        final httpsUrl = url.replaceFirst('http://', 'https://');
        final httpsUri = Uri.parse(httpsUrl);
        if (await canLaunchUrl(httpsUri)) {
          await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Could not open: $url')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open: $url')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening: $url')));
      }
    }
  }

  Future<void> _performAction(String actionType, String url) async {
    switch (actionType) {
      case 'call':
        setState(() => _isLoadingCall = true);
        break;
      case 'whatsapp':
        setState(() => _isLoadingWhatsApp = true);
        break;
      case 'locate':
        setState(() => _isLoadingLocate = true);
        break;
      case 'website':
        setState(() => _isLoadingWebsite = true);
        break;
      default:
        break;
    }

    try {
      await _launchUrl(url);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCall = false;
          _isLoadingWhatsApp = false;
          _isLoadingLocate = false;
          _isLoadingWebsite = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showOwnerServiceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.view_list),
              label: const Text('View Services'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade100,
                foregroundColor: Colors.teal,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServicesScreen(
                      businessName: name,
                      businessCategory: category,
                      businessId: widget.item['id'] ?? '',
                      ownerEmail: ownerEmail,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 28,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    4,
                    (index) => Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                              5,
                              (_) => Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LottieOrPlaceholder(
            assetPath: 'lottie/error_animation.json',
            height: 200,
          ),
          const SizedBox(height: 20),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2D3F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dataError ?? 'Unknown error',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _dataError = null;
                _isDataLoading = true;
              });
              _initializeData();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      screenName: 'DetailScreen',
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              DetailHeroImage(
                imageUrl: image,
                onBack: () => Navigator.pop(context),
                onToggleSave: _onToggleSave,
                isSaved: _isSaved,
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.65,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: _isDataLoading
                          ? _buildShimmerLoading()
                          : _dataError != null
                          ? _buildErrorState()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.2,
                                                color: Color(0xFF0A2D3F),
                                              ),
                                            ),
                                          ),
                                          if (ownerEmail == 'admin@findora.cok')
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                              ),
                                              child: OutlinedButton.icon(
                                                onPressed: _handleClaimTap,
                                                icon: const Icon(
                                                  Icons.business,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Claim this Business',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                    width: 1.5,
                                                  ),
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    32,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          else if (ownerEmail !=
                                              'admin@findora.cok')
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                              ),
                                              child: OutlinedButton.icon(
                                                onPressed:
                                                    null, // Non-functional badge
                                                icon: const Icon(
                                                  Icons.verified,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Verified Business',
                                                ),
                                                style: ButtonStyle(
                                                  foregroundColor:
                                                      WidgetStateProperty.all(
                                                        Colors.green,
                                                      ),
                                                  side: WidgetStateProperty.all(
                                                    const BorderSide(
                                                      color: Colors.green,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      WidgetStateProperty.all(
                                                        Colors.transparent,
                                                      ),
                                                  padding: WidgetStateProperty.all(
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                  ),
                                                  minimumSize:
                                                      WidgetStateProperty.all(
                                                        const Size(0, 32),
                                                      ),
                                                  shape: WidgetStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      '(${averageRating.toStringAsFixed(1)})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < averageRating.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 18,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Reviews',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: Colors.teal,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      subcategory,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.teal,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Colors.teal,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      timing,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                DetailQuickActions(
                                  contact: contact,
                                  whatsapp: whatsapp,
                                  website: website,
                                  liveLocation: liveLocation,
                                  category: category,
                                  ownerEmail: ownerEmail,
                                  currentEmail: _currentEmail,
                                  isLoadingCall: _isLoadingCall,
                                  isLoadingWhatsApp: _isLoadingWhatsApp,
                                  isLoadingLocate: _isLoadingLocate,
                                  isLoadingWebsite: _isLoadingWebsite,
                                  onCall: contact.isNotEmpty
                                      ? () => _performAction(
                                          'call',
                                          'tel:$contact',
                                        )
                                      : () => _showSnack('No contact number'),
                                  onWhatsApp: whatsapp.isNotEmpty
                                      ? () => _performAction(
                                          'whatsapp',
                                          'https://wa.me/$whatsapp',
                                        )
                                      : () => _showSnack('No WhatsApp number'),
                                  onLocate: liveLocation.isNotEmpty
                                      ? () => _performAction(
                                          'locate',
                                          liveLocation,
                                        )
                                      : () => _showSnack('No location link'),
                                  onWebsite: website.isNotEmpty
                                      ? () => _performAction('website', website)
                                      : () => _showSnack('No website link'),
                                  onInstagram: instagram.isNotEmpty
                                      ? () => _performAction(
                                          'instagram',
                                          instagram,
                                        )
                                      : () => _showSnack('No Instagram link'),
                                  onFacebook: facebook.isNotEmpty
                                      ? () =>
                                            _performAction('facebook', facebook)
                                      : () => _showSnack('No Facebook link'),
                                  onServices: () {
                                    if (_currentEmail == ownerEmail) {
                                      _showOwnerServiceOptions(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ServicesScreen(
                                            businessName: name,
                                            businessCategory: category,
                                            businessId: widget.item['id'] ?? '',
                                            ownerEmail: ownerEmail,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onShare: _shareBusiness,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WriteReviewScreen(
                                            businessId: widget.item['id'] ?? '',
                                            businessName: name,
                                            userEmail: _currentEmail,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: FaIcon(
                                        FontAwesomeIcons.penToSquare,
                                        size: 18,
                                      ),
                                    ),
                                    label: const Text('Write a Review'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.teal,
                                      side: const BorderSide(
                                        color: Colors.teal,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: liveLocation.isNotEmpty
                                        ? () => _launchUrl(liveLocation)
                                        : () => _showSnack(
                                            'No location available',
                                          ),
                                    icon: const Icon(
                                      Icons.directions,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Get Directions',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),
                                const Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0A2D3F),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Reviews',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DetailReviewsList(
                                  businessId: widget.item['id'] ?? '',
                                  averageRating: averageRating,
                                  onSeeAll: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AllReviewsScreen(
                                          placeName: name,
                                          businessId: widget.item['id'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 30),
                                DetailMapWidget(lat: latitude, lng: longitude),
                                const SizedBox(height: 16),
                                const Center(
                                  child: Text(
                                    '© 2026 Findora. All rights reserved.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareBusiness() async {
    try {
      final deepLink = DeepLinkService.generateShareableBusinessLink(
        widget.item['id'] ?? '',
      );
      await Share.share(
        'Check out this business: $name\\n\\n$deepLink',
        subject: 'Business Recommendation: $name',
      );
    } catch (e) {
      _showSnack('Failed to share business');
    }
  }
}
