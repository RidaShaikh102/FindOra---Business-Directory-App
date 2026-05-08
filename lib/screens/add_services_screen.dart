import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:findora/models/service_model.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/supabase_service.dart';

import 'services_screen.dart';

class AddServiceScreen extends StatefulWidget {
  final String businessName;
  final String businessCategory;
  final String businessId;
  final String ownerEmail;

  const AddServiceScreen({
    super.key,
    required this.businessName,
    required this.businessCategory,
    required this.businessId,
    required this.ownerEmail,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final LocalStorageService _storageService = LocalStorageService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSaving = false;
  bool _isAvailable = true;

  late String itemType;
  late String pluralLabel;

  @override
  void initState() {
    super.initState();
    _setDynamicLabels();
    AnalyticsService.logScreenView('AddServiceScreen');
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _setDynamicLabels() {
    final cat = widget.businessCategory.toLowerCase();
    if (cat.contains('restaurant') || cat.contains('food')) {
      itemType = 'Menu Item';
      pluralLabel = 'Menu';
    } else if (cat.contains('hospital') || cat.contains('clinic')) {
      itemType = 'Doctor';
      pluralLabel = 'Doctors';
    } else if (cat.contains('pharmacy')) {
      itemType = 'Medicine';
      pluralLabel = 'Medicines';
    } else if (cat.contains('salon') ||
        cat.contains('beauty') ||
        cat.contains('spa')) {
      itemType = 'Service';
      pluralLabel = 'Services';
    } else if (cat.contains('education') || cat.contains('academy')) {
      itemType = 'Course';
      pluralLabel = 'Courses';
    } else if (cat.contains('store') || cat.contains('shop')) {
      itemType = 'Product';
      pluralLabel = 'Products';
    } else {
      itemType = 'Service';
      pluralLabel = 'Services';
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final imageBytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = imageBytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read the selected image: $e')),
      );
    }
  }

  Future<String?> _uploadToSupabase(
    XFile file,
    String businessId,
    String serviceId,
  ) async {
    return SupabaseService.uploadServiceImage(
      imageFile: file,
      businessId: businessId,
      serviceId: serviceId,
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String imageUrl = '';
      final serviceId = DateTime.now().millisecondsSinceEpoch.toString();
      if (_selectedImage != null) {
        imageUrl =
            await _uploadToSupabase(
              _selectedImage!,
              widget.businessId,
              serviceId,
            ) ??
            '';
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final service = ServiceModel(
        id: serviceId,
        businessId: widget.businessId,
        businessName: widget.businessName,
        ownerEmail: widget.ownerEmail,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text.trim()),
        image: imageUrl,
        category: widget.businessCategory,
        isAvailable: _isAvailable,
        createdAt: now,
        updatedAt: now,
      );

      await _storageService.saveService(widget.businessId, service.toJson());

      if (!mounted) return;
      await AnalyticsService.logAction('add_service');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemType added successfully!'),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ServicesScreen(
            businessName: widget.businessName,
            businessCategory: widget.businessCategory,
            businessId: widget.businessId,
            ownerEmail: widget.ownerEmail,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add $itemType. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String catPriceLabel(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('hospital') || cat.contains('clinic')) {
      return 'Consultation Fee (PKR)';
    }
    if (cat.contains('restaurant') || cat.contains('food')) {
      return 'Menu Item Price (PKR)';
    }
    if (cat.contains('pharmacy')) return 'Medicine Price (PKR)';
    if (cat.contains('education') || cat.contains('academy')) {
      return 'Course Fee (PKR)';
    }
    return 'Price (PKR)';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 500 ? 500.0 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A2D3F),
                const Color(0xE60A2D3F),
                Colors.teal.shade700,
              ],
            ),
          ),
        ),
        title: Text('Add $itemType for ${widget.businessName}'),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: maxWidth,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                  elevation: 3,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _selectedImage == null
                          ? Container(
                              decoration: BoxDecoration(
                                color: const Color(0x0D009688),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add $itemType Image',
                                      style: const TextStyle(
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputCard(
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '$itemType Name',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter $itemType name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputCard(
                  child: TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '$itemType Description',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter $itemType description';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputCard(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: catPriceLabel(widget.businessCategory),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      final price = double.tryParse(value?.trim() ?? '');
                      if (price == null || price <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.teal, width: 1),
                  ),
                  elevation: 2,
                  child: SwitchListTile(
                    value: _isAvailable,
                    activeThumbColor: Colors.teal,
                    title: const Text('Available for orders'),
                    subtitle: Text(
                      _isAvailable
                          ? 'Customers can add this item to cart.'
                          : 'Keep it hidden from ordering for now.',
                    ),
                    onChanged: (value) {
                      setState(() => _isAvailable = value);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveService,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save $itemType',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.teal, width: 1),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      ),
    );
  }
}
