import 'package:findora/config/marketplace_config.dart';

class OrderStatusEventModel {
  final String status;
  final int timestamp;
  final String actor;
  final String message;

  const OrderStatusEventModel({
    required this.status,
    required this.timestamp,
    required this.actor,
    required this.message,
  });

  factory OrderStatusEventModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusEventModel(
      status: json['status']?.toString() ?? 'pending',
      timestamp: _asInt(json['timestamp']) ?? 0,
      actor: json['actor']?.toString() ?? 'system',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp,
      'actor': actor,
      'message': message,
    };
  }
}

class OrderItemModel {
  final String serviceId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.serviceId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  /// Alias for older code paths.
  double get totalPrice => lineTotal;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      serviceId: json['serviceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: _asDouble(json['price']),
      quantity: _asInt(json['quantity']) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'lineTotal': lineTotal,
      'totalPrice': lineTotal,
    };
  }
}

class OrderModel {
  final String id;
  final String businessId;
  final String businessName;
  /// Seller Firebase Auth uid when known; may be empty for legacy orders.
  final String sellerId;
  final String ownerEmail;
  final String userId;
  final String customerId;
  final String customerEmail;
  final String customerName;
  final String customerPhone;
  final String note;
  final String ownerNote;
  final String status;
  final int estimatedReadyAt;
  final List<OrderItemModel> items;
  final List<OrderStatusEventModel> statusHistory;
  final int itemCount;
  final double subtotal;
  final double deliveryFee;
  /// Grand total (COD). If 0 in storage, UI falls back to [subtotal] + [deliveryFee].
  final double totalAmount;
  final String deliveryMode;
  final String userCity;
  final String sellerCity;
  final double commissionRate;
  /// Set when status becomes `delivered` / legacy `completed`.
  final double commission;
  final double sellerEarning;
  final String paymentMethod;
  final String courierCarrier;
  final String courierTrackingId;
  final int deliveredAt;
  final int createdAt;
  final int updatedAt;

  const OrderModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.sellerId,
    required this.ownerEmail,
    required this.userId,
    required this.customerId,
    required this.customerEmail,
    required this.customerName,
    required this.customerPhone,
    required this.note,
    required this.ownerNote,
    required this.status,
    required this.estimatedReadyAt,
    required this.items,
    required this.statusHistory,
    required this.itemCount,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.deliveryMode,
    required this.userCity,
    required this.sellerCity,
    required this.commissionRate,
    required this.commission,
    required this.sellerEarning,
    required this.paymentMethod,
    required this.courierCarrier,
    required this.courierTrackingId,
    required this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  double get effectiveTotal {
    if (totalAmount > 0) return totalAmount;
    return subtotal + deliveryFee;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    final rawHistory = (json['statusHistory'] as List?) ?? const [];
    final sub = _asDouble(json['subtotal']);
    final fee = _asDouble(json['deliveryFee']);
    var total = _asDouble(json['totalAmount']);
    if (total <= 0) total = sub + fee;

    return OrderModel(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['customerId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      ownerNote: json['ownerNote']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      estimatedReadyAt: _asInt(json['estimatedReadyAt']) ?? 0,
      items: rawItems
          .map(
            (item) => OrderItemModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      statusHistory: rawHistory
          .map(
            (item) =>
                OrderStatusEventModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      itemCount: _asInt(json['itemCount']) ?? 0,
      subtotal: sub,
      deliveryFee: fee,
      totalAmount: total,
      deliveryMode: json['deliveryMode']?.toString() ?? 'local',
      userCity: json['userCity']?.toString() ?? '',
      sellerCity: json['sellerCity']?.toString() ?? '',
      commissionRate: _asDouble(json['commissionRate']) > 0
          ? _asDouble(json['commissionRate'])
          : kDefaultCommissionRate,
      commission: _asDouble(json['commission']),
      sellerEarning: _asDouble(json['sellerEarning']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      courierCarrier: json['courierCarrier']?.toString() ?? '',
      courierTrackingId: json['courierTrackingId']?.toString() ?? '',
      deliveredAt: _asInt(json['deliveredAt']) ?? 0,
      createdAt: _asInt(json['createdAt']) ?? 0,
      updatedAt: _asInt(json['updatedAt']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'businessName': businessName,
      'sellerId': sellerId,
      'ownerEmail': ownerEmail,
      'userId': userId,
      'customerId': customerId,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'note': note,
      'ownerNote': ownerNote,
      'status': status,
      'estimatedReadyAt': estimatedReadyAt,
      'items': items.map((item) => item.toJson()).toList(),
      'statusHistory': statusHistory.map((item) => item.toJson()).toList(),
      'itemCount': itemCount,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'deliveryMode': deliveryMode,
      'userCity': userCity,
      'sellerCity': sellerCity,
      'commissionRate': commissionRate,
      'commission': commission,
      'sellerEarning': sellerEarning,
      'paymentMethod': paymentMethod,
      'courierCarrier': courierCarrier,
      'courierTrackingId': courierTrackingId,
      'deliveredAt': deliveredAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  OrderModel copyWith({
    String? status,
    String? ownerNote,
    int? estimatedReadyAt,
    List<OrderStatusEventModel>? statusHistory,
    int? updatedAt,
    double? commission,
    double? sellerEarning,
    int? deliveredAt,
  }) {
    return OrderModel(
      id: id,
      businessId: businessId,
      businessName: businessName,
      sellerId: sellerId,
      ownerEmail: ownerEmail,
      userId: userId,
      customerId: customerId,
      customerEmail: customerEmail,
      customerName: customerName,
      customerPhone: customerPhone,
      note: note,
      ownerNote: ownerNote ?? this.ownerNote,
      status: status ?? this.status,
      estimatedReadyAt: estimatedReadyAt ?? this.estimatedReadyAt,
      items: items,
      statusHistory: statusHistory ?? this.statusHistory,
      itemCount: itemCount,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      deliveryMode: deliveryMode,
      userCity: userCity,
      sellerCity: sellerCity,
      commissionRate: commissionRate,
      commission: commission ?? this.commission,
      sellerEarning: sellerEarning ?? this.sellerEarning,
      paymentMethod: paymentMethod,
      courierCarrier: courierCarrier,
      courierTrackingId: courierTrackingId,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get canCustomerCancel {
    const cancellable = {'pending', 'accepted', 'confirmed'};
    return cancellable.contains(status);
  }

  bool get hasEta => estimatedReadyAt > 0;

  bool get isDelivered =>
      status == 'delivered' || status == 'completed';
}

/// Status values for new marketplace flow. Legacy: `confirmed` ≈ accepted, `completed` ≈ delivered.
const List<String> kOrderStatuses = <String>[
  'pending',
  'accepted',
  'in_progress',
  'out_for_delivery',
  'delivered',
  'cancelled',
];

/// All statuses including legacy (for filters / admin).
const List<String> kAllOrderStatusFilters = <String>[
  ...kOrderStatuses,
  'confirmed',
  'completed',
];

String orderStatusLabel(String status) {
  switch (status) {
    case 'confirmed':
      return 'Accepted';
    case 'completed':
      return 'Delivered';
    case 'in_progress':
      return 'In progress';
    case 'out_for_delivery':
      return 'Out for delivery';
    case 'cancelled':
      return 'Cancelled';
    case 'delivered':
      return 'Delivered';
    case 'accepted':
      return 'Accepted';
    case 'pending':
      return 'Pending';
    default:
      if (status.isEmpty) return 'Unknown';
      return status[0].toUpperCase() + status.substring(1);
  }
}

bool orderStatusIsActive(String status) {
  const active = {
    'pending',
    'accepted',
    'confirmed',
    'in_progress',
    'out_for_delivery',
  };
  return active.contains(status);
}

bool orderStatusIsTerminal(String status) {
  return status == 'delivered' ||
      status == 'completed' ||
      status == 'cancelled';
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
