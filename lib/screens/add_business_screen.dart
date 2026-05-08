import 'dart:io';
import 'package:findora/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // ✅ added for web detection
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:findora/config/marketplace_config.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/services/local_storage_service.dart';

class AddBusinessScreen extends StatefulWidget {
  final Map<String, dynamic>? existingBusiness;

  const AddBusinessScreen({super.key, this.existingBusiness});

  @override
  State<AddBusinessScreen> createState() => _AddBusinessScreenState();
}

class _AddBusinessScreenState extends State<AddBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  final TextEditingController _nameController = TextEditingController();
  String _category = 'Restaurants';
  String _subcategory = 'Restaurants';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _timingController = TextEditingController();
  final TextEditingController _holidayController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _liveLocationController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();

  final Map<String, List<String>> categoryMap = {
    'Restaurants': ['Restaurants', 'Cafes', 'Bakeries', 'Hotels', 'Carts'],
    'Shopping': ['Clothing', 'Electronics', 'Grocery', 'Gifts'],
    'Health & Beauty': ['Salons', 'Spas', 'Pharmacies', 'Clinics'],
    'Education': ['Schools', 'Colleges', 'Coaching Centers', 'Libraries'],
    'Services': ['Repair', 'Laundry', 'Delivery', 'Photography'],
    'Entertainment': ['Cinemas', 'Parks', 'Arcades', 'Events'],
    'Online': [
      'E-Commerce & Retail',
      'Education & Training',
      'Digital & Freelance Services',
      'Marketing & Media',
      'Business & Professional Services',
    ],
    'Others': ['Other'],
  };

  @override
  void initState() {
    super.initState();
    _cityController.text = kMarketplaceLocalCity;
    _subcategory = categoryMap[_category]!.first;
    if (widget.existingBusiness != null) {
      _populateExistingData();
    }
    AnalyticsService.logScreenView(
      widget.existingBusiness != null
          ? 'EditBusinessScreen'
          : 'AddBusinessScreen',
    );
  }

  void _populateExistingData() {
    final business = widget.existingBusiness!;
    _nameController.text = business['name'] ?? '';
    _category = business['category'] ?? 'Restaurants';
    _subcategory = business['subcategory'] ?? 'Restaurants';
    _addressController.text = business['address'] ?? '';
    _cityController.text =
        (business['city']?.toString().trim().isNotEmpty == true)
        ? business['city'].toString()
        : kMarketplaceLocalCity;
    _contactController.text = business['contact'] ?? '';
    _whatsappController.text = business['whatsapp'] ?? '';
    _websiteController.text = business['website'] ?? '';
    _timingController.text = business['timing'] ?? '';
    _holidayController.text = business['holiday'] ?? '';
    _descriptionController.text = business['description'] ?? '';
    _liveLocationController.text = business['liveLocation'] ?? '';
    _latitude = business['latitude'];
    _longitude = business['longitude'];
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String address = '';
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final addressParts = <String>[];
          if (place.street?.isNotEmpty ?? false) {
            addressParts.add(place.street!);
          }
          if (place.subLocality?.isNotEmpty ?? false) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality?.isNotEmpty ?? false) {
            addressParts.add(place.locality!);
          }
          if (place.postalCode?.isNotEmpty ?? false) {
            addressParts.add(place.postalCode!);
          }
          if (place.country?.isNotEmpty ?? false) {
            addressParts.add(place.country!);
          }
          address = addressParts.join(', ');
        }
      } catch (_) {}

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text = address;
        _liveLocationController.text =
            'https://www.google.com/maps?q=$_latitude,$_longitude';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location added successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  void _parseGoogleMapsLink() {
    final url = _liveLocationController.text.trim();
    if (url.isEmpty) return;

    final regex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
    final match = regex.firstMatch(url);

    if (match != null) {
      setState(() {
        _latitude = double.tryParse(match.group(1)!);
        _longitude = double.tryParse(match.group(2)!);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not extract coordinates from the link.'),
        ),
      );
    }
  }

  void _viewOnMap() {
    if (_latitude != null && _longitude != null) {
      MapsLauncher.launchCoordinates(_latitude!, _longitude!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available to view on map.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    if (_liveLocationController.text.isNotEmpty &&
        (_latitude == null || _longitude == null)) {
      _parseGoogleMapsLink();
    }

    String? imageUrl;
    if (_selectedImage != null) {
      try {
        // Use SupabaseService for image upload
        final businessId =
            widget.existingBusiness?['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await SupabaseService.uploadBusinessImage(
          imageFile: _selectedImage!,
          businessId: businessId,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
        setState(() => _isLoading = false);
        return;
      }
    } else if (widget.existingBusiness?['image'] != null) {
      imageUrl = widget.existingBusiness!['image'];
    }

    if (_category != 'Online' && (_latitude == null || _longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a location for the business.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final storage = LocalStorageService();
    final ownerEmail =
        widget.existingBusiness?['ownerEmail'] ??
        await AuthService().getCurrentUserEmail() ??
        '';
    final status = widget.existingBusiness?['status'] ?? 'pending';

    final businessData = {
      'image': imageUrl ?? '',
      'name': _nameController.text.trim(),
      'category': _category,
      'subcategory': _subcategory,
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? kMarketplaceLocalCity
          : _cityController.text.trim(),
      'contact': _contactController.text.trim(),
      'whatsapp': _whatsappController.text.trim(),
      'website': _websiteController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'facebook': _facebookController.text.trim(),
      'timing': _timingController.text.trim(),
      'holiday': _holidayController.text.trim(),
      'liveLocation': _liveLocationController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'description': _descriptionController.text.trim(),
      'ownerEmail': ownerEmail,
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.existingBusiness != null &&
          widget.existingBusiness!['id'] != null) {
        // Update existing business
        businessData['id'] = widget.existingBusiness!['id'];
        businessData['createdAt'] =
            widget.existingBusiness!['createdAt'] ??
            DateTime.now().toIso8601String();
        await storage.updateBusiness(businessData['id'], businessData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business updated successfully!')),
        );
      } else {
        // Check for duplicates
        final businessName = (businessData['name'] as String).trim();
        final duplicateExists = await storage.businessNameExists(businessName);

        if (duplicateExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A business with this name already exists!'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Add new business
        businessData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        businessData['createdAt'] = DateTime.now().toIso8601String();
        await storage.saveBusiness(businessData);

        // Show approval popup
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Business Submitted'),
              content: const Text(
                'Your business will be visible to users after approval.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business added successfully!')),
        );
      }

      if (!mounted) return;
      await AnalyticsService.logAction(
        widget.existingBusiness != null ? 'edit_business' : 'add_business',
      );
      Navigator.pop(context, businessData);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving business: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    _timingController.dispose();
    _holidayController.dispose();
    _descriptionController.dispose();
    _liveLocationController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A2D3F),
                Color.fromRGBO(10, 45, 63, 0.9),
                Colors.teal.shade700,
              ],
            ),
          ),
        ),
        title: Text(
          widget.existingBusiness != null ? 'Edit Business' : 'Add Business',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _selectedImage == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Tap to upload logo"),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  _selectedImage!.path,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              ..._buildTextFields(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _viewOnMap,
                    icon: const Icon(Icons.map),
                    label: const Text('View on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTextFields() {
    return [
      _buildTextField(_nameController, 'Business Name *', true),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildDropdown(
              'Category',
              _category,
              categoryMap.keys.toList(),
              (v) {
                if (v == null) return;
                setState(() {
                  _category = v;
                  _subcategory = categoryMap[_category]!.first;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              'Subcategory',
              _subcategory,
              categoryMap[_category]!,
              (v) {
                if (v == null) return;
                setState(() => _subcategory = v);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildTextField(
        _addressController,
        'Address${_category == 'Online' ? '' : ' *'}',
        _category != 'Online',
      ),
      const SizedBox(height: 12),
      _buildTextField(_cityController, 'Business city (delivery zone) *', true),
      const SizedBox(height: 12),
      _buildTextField(
        _contactController,
        'Contact',
        false,
        keyboard: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        _whatsappController,
        'WhatsApp Number',
        false,
        keyboard: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        _websiteController,
        'Website',
        false,
        keyboard: TextInputType.url,
      ),
      const SizedBox(height: 12),
      _buildTextField(_timingController, 'Timing (e.g. 9AM - 9PM) *', true),
      const SizedBox(height: 12),
      _buildTextField(_holidayController, 'Holiday (e.g. Sunday)', false),
      const SizedBox(height: 12),
      // Business Description
      TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Business Description *',
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        _instagramController,
        'Instagram Link',
        false,
        keyboard: TextInputType.url,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        _facebookController,
        'Facebook Link',
        false,
        keyboard: TextInputType.url,
      ),
      const SizedBox(height: 12),
      if (_category != 'Online')
        _buildTextField(
          _liveLocationController,
          'Live Location Link (Google Maps URL)',
          false,
          keyboard: TextInputType.url,
        ),
    ];
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      isExpanded: true,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 2),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
