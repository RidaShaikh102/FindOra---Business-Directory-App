import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../models/service_model.dart';

enum AddToCartResult { added, updated, requiresReplacement }

class CartState {
  final String? businessId;
  final String? businessName;
  final String? ownerEmail;
  final List<CartItemModel> items;

  const CartState({
    this.businessId,
    this.businessName,
    this.ownerEmail,
    this.items = const <CartItemModel>[],
  });

  bool get isEmpty => items.isEmpty;

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  CartState copyWith({
    String? businessId,
    String? businessName,
    String? ownerEmail,
    List<CartItemModel>? items,
    bool clearBusiness = false,
  }) {
    return CartState(
      businessId: clearBusiness ? null : businessId ?? this.businessId,
      businessName: clearBusiness ? null : businessName ?? this.businessName,
      ownerEmail: clearBusiness ? null : ownerEmail ?? this.ownerEmail,
      items: items ?? this.items,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  AddToCartResult addService(ServiceModel service, {int quantity = 1}) {
    if (!service.isAvailable) {
      return AddToCartResult.updated;
    }

    if (state.businessId != null &&
        state.businessId != service.businessId &&
        state.items.isNotEmpty) {
      return AddToCartResult.requiresReplacement;
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.service.id == service.id,
    );
    final nextItems = [...state.items];
    if (existingIndex >= 0) {
      final existing = nextItems[existingIndex];
      nextItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
      state = state.copyWith(
        businessId: service.businessId,
        businessName: service.businessName,
        ownerEmail: service.ownerEmail,
        items: nextItems,
      );
      return AddToCartResult.updated;
    }

    nextItems.add(CartItemModel(service: service, quantity: quantity));
    state = state.copyWith(
      businessId: service.businessId,
      businessName: service.businessName,
      ownerEmail: service.ownerEmail,
      items: nextItems,
    );
    return AddToCartResult.added;
  }

  void replaceWithService(ServiceModel service, {int quantity = 1}) {
    state = CartState(
      businessId: service.businessId,
      businessName: service.businessName,
      ownerEmail: service.ownerEmail,
      items: [CartItemModel(service: service, quantity: quantity)],
    );
  }

  void replaceWithItems({
    required String businessId,
    required String businessName,
    required String ownerEmail,
    required List<CartItemModel> items,
  }) {
    if (items.isEmpty) {
      clear();
      return;
    }

    state = CartState(
      businessId: businessId,
      businessName: businessName,
      ownerEmail: ownerEmail,
      items: items,
    );
  }

  void updateQuantity(String serviceId, int quantity) {
    if (quantity <= 0) {
      removeItem(serviceId);
      return;
    }

    final nextItems = state.items.map((item) {
      if (item.service.id != serviceId) return item;
      return item.copyWith(quantity: quantity);
    }).toList();

    state = state.copyWith(items: nextItems);
  }

  void removeItem(String serviceId) {
    final nextItems = state.items
        .where((item) => item.service.id != serviceId)
        .toList();

    if (nextItems.isEmpty) {
      clear();
      return;
    }

    state = state.copyWith(items: nextItems);
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
