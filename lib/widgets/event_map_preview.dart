import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EventMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;

  const EventMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final point = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 170,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.unilink',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: cs.primary,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
