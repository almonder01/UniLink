import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EventLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const EventLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<EventLocationPickerScreen> createState() =>
      _EventLocationPickerScreenState();
}

class _EventLocationPickerScreenState extends State<EventLocationPickerScreen> {
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLocation ?? const LatLng(2.8329, 101.7077);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Location')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15,
              onTap: (_, point) => setState(() => _selectedLocation = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.unilink',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.location_on_rounded,
                      color: cs.primary,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.place_rounded, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_selectedLocation.latitude.toStringAsFixed(5)}, '
                        '${_selectedLocation.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, _selectedLocation),
                      child: const Text('Use'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
