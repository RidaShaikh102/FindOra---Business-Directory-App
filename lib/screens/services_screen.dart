import 'dart:io';
import 'package:findora/screens/add_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/analytics_service.dart';

class ServicesScreen extends StatefulWidget {
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
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> services = [];
  bool isLoading = false;
  String _currentEmail = '';

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
      final fetchedServices = await _storageService.getServices(
        widget.businessId,
      );
      setState(() {
        services = fetchedServices;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading services: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addNewService() async {
    final result = await Navigator.push(
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

    if (result != null) {
      _loadServices();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Color(0xFF0A2D3F).withOpacity(0.9),
                Colors.teal.shade700,
              ],
            ),
          ),
        ),
        title: Text(
          "${widget.businessName} Services",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
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
                      ? const Center(
                          child: Text(
                            "No services added yet.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.teal.shade100,
                                  width: 1,
                                ),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    service['image'] != null &&
                                            service['image']
                                                .toString()
                                                .isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              File(service['image']),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: Colors.teal.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.design_services,
                                              color: Colors.teal,
                                              size: 30,
                                            ),
                                          ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service['name'] ??
                                                'Unnamed Service',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            service['description'] ??
                                                'No description provided',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            service['price'] != null &&
                                                    service['price']
                                                        .toString()
                                                        .isNotEmpty
                                                ? "Rs. ${service['price']}"
                                                : '',
                                            style: const TextStyle(
                                              color: Colors.teal,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
      floatingActionButton: _currentEmail == widget.ownerEmail
          ? FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: _addNewService,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
