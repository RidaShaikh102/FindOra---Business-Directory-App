import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/marketplace_config.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../screens/my_orders_screen.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import 'package:findora/screens/coming_soon_screen.dart';

class _DeliveryQuote {
  final String deliveryMode; // local | courier
  final double deliveryFee;

  const _DeliveryQuote({required this.deliveryMode, required this.deliveryFee});
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  final AuthService _authService = AuthService();
  final LocalStorageService _storageService = LocalStorageService();

  bool _isSubmitting = false;
  Future<_DeliveryQuote>? _deliveryQuoteFuture;

  @override
  void initState() {
    super.initState();
    _prefillUser();
    AnalyticsService.logScreenView('CartScreen');
  }

  void _ensureDeliveryQuote(CartState cart) {
    final businessId = cart.businessId ?? '';
    if (businessId.isEmpty || cart.items.isEmpty) {
      _deliveryQuoteFuture = null;
      return;
    }
    _deliveryQuoteFuture ??= _computeDeliveryQuote(businessId);
  }

  Future<_DeliveryQuote> _computeDeliveryQuote(String businessId) async {
    final business = await _storageService.getBusinessById(businessId);
    final sellerCity =
        business?['city']?.toString().trim() ?? kMarketplaceLocalCity;
    final userCity = await _authService.getUserCity() ?? '';

    final isLocal =
        citiesMatchForLocalDelivery(userCity, sellerCity) &&
        isInLocalHub(userCity);
    final mode = isLocal ? 'local' : 'courier';
    final fee = mode == 'local' ? kLocalDeliveryFee : kCourierDeliveryFee;

    return _DeliveryQuote(deliveryMode: mode, deliveryFee: fee);
  }

  Future<void> _prefillUser() async {
    final name = await _authService.getCurrentUserName();
    final email = await _authService.getCurrentUserEmail();
    if (!mounted) return;

    _nameController.text = name ?? '';
    _emailController.text = email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    // ignore: dead_code
    return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty || !_formKey.currentState!.validate()) {
      return;
    }

    final businessId = cart.businessId ?? '';
    final ownerEmail = cart.ownerEmail ?? '';
    final businessName = cart.businessName ?? '';
    if (businessId.isEmpty || ownerEmail.isEmpty || businessName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This business is not ready to receive orders yet.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final business = await _storageService.getBusinessById(businessId);
      if (business == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load business details. Try again later.'),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      var sellerCity =
          business['city']?.toString().trim() ?? kMarketplaceLocalCity;
      if (sellerCity.isEmpty) sellerCity = kMarketplaceLocalCity;

      if (!isInLocalHub(sellerCity)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Orders are only supported for sellers in $kMarketplaceLocalCity for now.',
            ),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final userCity = await _authService.getUserCity();
      if (userCity == null || userCity.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set your delivery city in Profile first.'),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final localDelivery =
          citiesMatchForLocalDelivery(userCity, sellerCity) &&
          isInLocalHub(userCity);
      final deliveryMode = localDelivery ? 'local' : 'courier';

      final sellerProfile = await _authService.getUserByEmail(ownerEmail);
      final sellerId = sellerProfile?['uid']?.toString() ?? '';

      final customerId = await _authService.getCurrentUserId() ?? '';
      final now = DateTime.now().millisecondsSinceEpoch;
      final orderId = now.toString();
      final items = cart.items
          .map(
            (item) => OrderItemModel(
              serviceId: item.service.id,
              name: item.service.name,
              image: item.service.image,
              price: item.service.price,
              quantity: item.quantity,
            ),
          )
          .toList();

      final deliveryFee = deliveryMode == 'local'
          ? kLocalDeliveryFee
          : kCourierDeliveryFee;
      final totalAmount = cart.subtotal + deliveryFee;

      final order = OrderModel(
        id: orderId,
        businessId: businessId,
        businessName: businessName,
        sellerId: sellerId,
        ownerEmail: ownerEmail,
        userId: customerId,
        customerId: customerId,
        customerEmail: _emailController.text.trim(),
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        note: _noteController.text.trim(),
        ownerNote: '',
        status: 'pending',
        estimatedReadyAt: 0,
        items: items,
        statusHistory: [
          OrderStatusEventModel(
            status: 'pending',
            timestamp: now,
            actor: 'customer',
            message: 'COD order placed',
          ),
        ],
        itemCount: cart.totalItems,
        subtotal: cart.subtotal,
        deliveryFee: deliveryFee,
        totalAmount: totalAmount,
        deliveryMode: deliveryMode,
        userCity: userCity,
        sellerCity: sellerCity,
        commissionRate: kDefaultCommissionRate,
        commission: 0,
        sellerEarning: 0,
        paymentMethod: 'COD',
        courierCarrier: '',
        courierTrackingId: '',
        deliveredAt: 0,
        createdAt: now,
        updatedAt: now,
      );

      await _storageService.saveOrder(order.toJson());
      await AnalyticsService.logAction('create_order');
      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      final shouldViewOrders = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order placed'),
          content: Text(
            'Your order has been sent to $businessName.\nReference: #$orderId',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('View orders'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (shouldViewOrders == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final bodyColor = Theme.of(context).scaffoldBackgroundColor;
    _ensureDeliveryQuote(cart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, color: Colors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ordering from',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                cart.businessName ?? 'Selected business',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...cart.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildItemImage(item.service.image, bodyColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.service.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.service.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Rs. ${_formatPrice(item.service.price)} each',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _quantityButton(
                                      icon: Icons.remove,
                                      onTap: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(
                                              item.service.id,
                                              item.quantity - 1,
                                            );
                                      },
                                    ),
                                    SizedBox(
                                      width: 36,
                                      child: Center(
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _quantityButton(
                                      icon: Icons.add,
                                      onTap: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(
                                              item.service.id,
                                              item.quantity + 1,
                                            );
                                      },
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Rs. ${_formatPrice(item.totalPrice)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .removeItem(item.service.id);
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
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
                  ),
                  const SizedBox(height: 8),
                  _buildSectionTitle('Contact details'),
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _nameController,
                    label: 'Your name',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _phoneController,
                    label: 'Phone number',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _noteController,
                    label: 'Order note (optional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: FutureBuilder<_DeliveryQuote>(
                      future: _deliveryQuoteFuture,
                      builder: (context, snapshot) {
                        final quote = snapshot.data;
                        final fee = quote?.deliveryFee ?? 0.0;
                        final total = cart.subtotal + fee;

                        return Column(
                          children: [
                            _summaryRow('Items', '${cart.totalItems}'),
                            const SizedBox(height: 10),
                            _summaryRow(
                              'Subtotal',
                              'Rs. ${_formatPrice(cart.subtotal)}',
                            ),
                            const SizedBox(height: 10),
                            _summaryRow(
                              quote == null
                                  ? 'Delivery'
                                  : quote.deliveryMode == 'local'
                                  ? 'Local delivery'
                                  : 'Courier (COD)',
                              'Rs. ${_formatPrice(fee)}',
                            ),
                            const SizedBox(height: 10),
                            _summaryRow(
                              'Total (COD)',
                              'Rs. ${_formatPrice(total)}',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(
                      _isSubmitting ? 'Placing order...' : 'Place order',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add services from a business to create your first order.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(String imageUrl, Color bodyColor) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: bodyColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.design_services, color: Colors.teal),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          color: bodyColor,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.teal.shade100),
        ),
        child: Icon(icon, size: 18, color: Colors.teal),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.teal.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.teal.shade100),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.teal, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
