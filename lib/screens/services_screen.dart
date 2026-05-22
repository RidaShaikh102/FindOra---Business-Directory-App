import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:findora/models/service_model.dart';
import 'package:findora/providers/cart_provider.dart';
import 'package:findora/screens/add_services_screen.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/widgets/responsive_layout.dart';
import 'package:findora/screens/owner/coming_soon_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final String businessName;
  final String businessCategory;
  final String businessId;
  final String ownerEmail;

  const ServicesScreen({
    super.key,
    required this.businessName,
    required this.businessCategory,
    required this.businessId,
    required this.ownerEmail,
  });

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final AuthService _authService = AuthService();

  List<ServiceModel> services = <ServiceModel>[];
  bool isLoading = false;
  String _currentEmail = '';

  bool get _isOwnerView => _currentEmail == widget.ownerEmail;
  bool get _businessCanReceiveOrders => widget.ownerEmail.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadCurrentUser();
    AnalyticsService.logScreenView('ServicesScreen');
  }

  Future<void> _loadCurrentUser() async {
    final email = await _authService.getCurrentUserEmail();
    if (mounted) {
      setState(() => _currentEmail = email ?? '');
    }
  }

  Future<void> _loadServices() async {
    setState(() => isLoading = true);
    try {
      final fetchedServices = await _storageService.getServiceModels(
        widget.businessId,
      );
      if (!mounted) return;
      setState(() {
        services = fetchedServices
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _addNewService() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          businessId: widget.businessId,
          businessName: widget.businessName,
          businessCategory: widget.businessCategory,
          ownerEmail: widget.ownerEmail,
        ),
      ),
    );

    if (mounted) {
      _loadServices();
    }
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
      // MaterialPageRoute(builder: (_) => const CartScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleAddToCart(ServiceModel service) async {
    if (!service.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This service is currently unavailable.')),
      );
      return;
    }

    if (!_businessCanReceiveOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordering will open once this business is claimed.'),
        ),
      );
      return;
    }

    final notifier = ref.read(cartProvider.notifier);
    final result = notifier.addService(service);

    if (result == AddToCartResult.requiresReplacement) {
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace current cart?'),
          content: const Text(
            'Your cart already contains services from another business. Replace it with this one?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );

      if (shouldReplace != true) return;
      notifier.replaceWithService(service);
    }

    await AnalyticsService.logAction('add_to_cart');
    if (!mounted) return;

    final count = ref.read(cartProvider).totalItems;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${service.name} added to cart. $count item(s) ready.'),
        action: SnackBarAction(label: 'View cart', onPressed: _openCart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(
      cartProvider.select((state) => state.totalItems),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A2D3F),
                const Color(0xFF0A2D3F).withValues(alpha: 0.9),
                Colors.teal.shade700,
              ],
            ),
          ),
        ),
        title: Text(
          '${widget.businessName} Services',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isOwnerView)
            IconButton(
              onPressed: _openCart,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (cartCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Color(0xFF0A2D3F),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: Center(
        child: ResponsivePageContainer(
          maxWidth: 1200,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: services.isEmpty
                      ? Center(
                          child: Text(
                            _isOwnerView
                                ? 'No services added yet.'
                                : 'No services available yet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final useGrid = ResponsiveLayout.isMediumOrLarger(
                              context,
                            );
                            if (!useGrid) {
                              return ListView.builder(
                                itemCount: services.length,
                                itemBuilder: (context, index) =>
                                    _buildServiceCard(services[index]),
                              );
                            }
                            final columns = ResponsiveLayout.adaptiveGridCount(
                              context,
                              compact: 1,
                              medium: 2,
                              expanded: 3,
                            );
                            return GridView.builder(
                              itemCount: services.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.45,
                                  ),
                              itemBuilder: (context, index) =>
                                  _buildServiceCard(services[index]),
                            );
                          },
                        ),
                ),
        ),
      ),
      floatingActionButton: _isOwnerView
          ? FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: _addNewService,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildServiceImage(ServiceModel service) {
    if (service.image.isEmpty) {
      return Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.design_services, color: Colors.teal, size: 34),
      );
    }

    final isNetworkImage = service.image.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: isNetworkImage
          ? Image.network(
              service.image,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _brokenImage(),
            )
          : Image.file(
              File(service.image),
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _brokenImage(),
            ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceImage(service),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name.isEmpty ? 'Unnamed Service' : service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description.isEmpty
                            ? 'No description provided'
                            : service.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Rs. ${_formatPrice(service.price)}',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _availabilityChip(service.isAvailable),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _isOwnerView
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Visible in your catalog'),
                    )
                  : ElevatedButton.icon(
                      onPressed:
                          service.isAvailable && _businessCanReceiveOrders
                          ? () => _handleAddToCart(service)
                          : null,
                      icon: Icon(
                        _businessCanReceiveOrders
                            ? Icons.add_shopping_cart
                            : Icons.lock_outline,
                      ),
                      label: Text(
                        _businessCanReceiveOrders
                            ? 'Add to cart'
                            : 'Ordering unavailable',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brokenImage() {
    return Container(
      width: 82,
      height: 82,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
    );
  }

  Widget _availabilityChip(bool isAvailable) {
    final color = isAvailable ? Colors.green : Colors.orange;
    final label = isAvailable ? 'Available' : 'Paused';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
