import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:findora/services/supabase_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'services_screen.dart'; // Import your ServicesScreen
import 'package:findora/services/analytics_service.dart';

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

  File? _selectedImage;
  bool _isSaving = false;

  final LocalStorageService _storageService = LocalStorageService();

  late String itemType;
  late String pluralLabel;

  @override
  void initState() {
    super.initState();
    _setDynamicLabels();
    AnalyticsService.logScreenView('AddServiceScreen');
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<String?> _uploadToSupabase(
    File file,
    String businessId,
    String serviceId,
  ) async {
    return await SupabaseService.uploadServiceImage(
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
            (await _uploadToSupabase(
              _selectedImage!,
              widget.businessId,
              serviceId,
            )) ??
            '';
      }

      final serviceData = {
        'id': serviceId,
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'image': imageUrl,
        'category': widget.businessCategory,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _storageService.saveService(widget.businessId, serviceData);

      if (mounted) {
        await AnalyticsService.logAction('add_service');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemType added successfully!'),
            backgroundColor: Colors.teal,
          ),
        );

        // Navigate to Services Screen for this business
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add $itemType. Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// Image Picker Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal, width: 1.5),
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
                                    "Add $itemType Image",
                                    style: const TextStyle(color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Name Field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal, width: 1),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "$itemType Name",
                      border: InputBorder.none,
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter $itemType name' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Description Field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal, width: 1),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "$itemType Description",
                      border: InputBorder.none,
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter $itemType description' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Price Field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.teal, width: 1),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: catPriceLabel(widget.businessCategory),
                      border: InputBorder.none,
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter a valid price' : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveService,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'Save $itemType',
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
    );
  }
}
