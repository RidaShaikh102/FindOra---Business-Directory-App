class BusinessModel {
  final String id;
  final String image;
  final String name;
  final String address;
  final String contact;
  final String whatsapp;
  final String website;
  final String liveLocation;
  final String subcategory;
  final String timing;
  final String description;
  final String category;
  final String ownerEmail;
  final String instagram;
  final String facebook;
  final double? latitude;
  final double? longitude;

  BusinessModel({
    required this.id,
    required this.image,
    required this.name,
    required this.address,
    required this.contact,
    required this.whatsapp,
    required this.website,
    required this.liveLocation,
    required this.subcategory,
    required this.timing,
    required this.description,
    required this.category,
    required this.ownerEmail,
    required this.instagram,
    required this.facebook,
    this.latitude,
    this.longitude,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] ?? '',
      image: json['image'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      contact: json['contact'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      website: json['website'] ?? '',
      liveLocation: json['liveLocation'] ?? '',
      subcategory: json['subcategory']?.toString() ?? '',
      timing: json['timing']?.toString() ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      instagram: json['instagram'] ?? '',
      facebook: json['facebook'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'name': name,
      'address': address,
      'contact': contact,
      'whatsapp': whatsapp,
      'website': website,
      'liveLocation': liveLocation,
      'subcategory': subcategory,
      'timing': timing,
      'description': description,
      'category': category,
      'ownerEmail': ownerEmail,
      'instagram': instagram,
      'facebook': facebook,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
