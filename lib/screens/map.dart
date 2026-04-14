import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../screens/detail_screen.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocalStorageService _storageService = LocalStorageService();
  Position? _currentPosition;
  double _currentZoom = 13.0;
  bool _isLoading = true;
  List<Map<String, dynamic>> businesses = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      final role = await AuthService().getCurrentUserRole();
      final email = await AuthService().getCurrentUserEmail();
      final loadedBusinesses = await _storageService.getVisibleBusinesses(
        role: role,
        email: email,
      );
      setState(() {
        businesses = loadedBusinesses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading businesses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    // Get current position
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move map to current location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _currentZoom,
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add current location marker if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF0A2D3F).withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.my_location,
                color: Color(0xFF0A2D3F),
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // Add business markers
    for (final business in businesses) {
      final lat = business['latitude'];
      final lng = business['longitude'];

      if (lat != null && lng != null) {
        markers.add(
          Marker(
            width: 60,
            height: 60,
            point: LatLng(lat.toDouble(), lng.toDouble()),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(item: business),
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      business['name'] ?? 'Business',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const Icon(Icons.location_on, color: Colors.red, size: 30),
                ],
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Businesses Near You'),
      //   backgroundColor: Theme.of(context).primaryColor,
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                    : const LatLng(27.7052, 68.8570), // Default center
                initialZoom: _currentZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.findora.app',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPosition != null)
            FloatingActionButton(
              heroTag: 'locate',
              backgroundColor: Color(0xFF0A2D3F),
              foregroundColor: Colors.white,
              onPressed: () {
                _mapController.move(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  15.0,
                );
              },
              child: const Icon(Icons.my_location),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'zoomIn',
            backgroundColor: Color(0xFF0A2D3F),
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() => _currentZoom += 1);
              _mapController.move(_mapController.camera.center, _currentZoom);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOut',
            backgroundColor: Color(0xFF0A2D3F),
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() => _currentZoom = _currentZoom - 1);
              _mapController.move(_mapController.camera.center, _currentZoom);
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
