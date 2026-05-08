class ServiceModel {
  final String id;
  final String businessId;
  final String businessName;
  final String ownerEmail;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool isAvailable;
  final int createdAt;
  final int updatedAt;

  const ServiceModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.ownerEmail,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(
    Map<String, dynamic> json, {
    String? businessId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      businessId: businessId ?? json['businessId']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _asDouble(json['price']),
      image: json['image']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: _asInt(json['createdAt']) ?? now,
      updatedAt: _asInt(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'businessName': businessName,
      'ownerEmail': ownerEmail,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? ownerEmail,
    String? name,
    String? description,
    double? price,
    String? image,
    String? category,
    bool? isAvailable,
    int? createdAt,
    int? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
