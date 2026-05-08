import 'service_model.dart';

class CartItemModel {
  final ServiceModel service;
  final int quantity;

  const CartItemModel({required this.service, required this.quantity});

  double get totalPrice => service.price * quantity;

  CartItemModel copyWith({ServiceModel? service, int? quantity}) {
    return CartItemModel(
      service: service ?? this.service,
      quantity: quantity ?? this.quantity,
    );
  }
}
