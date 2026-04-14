import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DetailMapWidget extends StatefulWidget {
  final double? lat;
  final double? lng;

  const DetailMapWidget({super.key, this.lat, this.lng});

  @override
  State<DetailMapWidget> createState() => _DetailMapWidgetState();
}

class _DetailMapWidgetState extends State<DetailMapWidget> {
  LatLng? _cachedPosition;

  @override
  void initState() {
    super.initState();
    _cachePosition();
  }

  void _cachePosition() {
    if (widget.lat != null && widget.lng != null) {
      _cachedPosition = LatLng(widget.lat!, widget.lng!);
    }
  }

  @override
  void didUpdateWidget(covariant DetailMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lat != oldWidget.lat || widget.lng != oldWidget.lng) {
      _cachePosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedPosition == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No location available for this business.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _cachedPosition!,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.findora.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _cachedPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
