import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMapWid extends StatelessWidget {
  final double latitude;
  final double longitude;
  final VoidCallback onDirectionsTap;

  const LocationMapWid({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng adLocation = LatLng(latitude, longitude);
    return Container(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: adLocation,
                  zoom: 15.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('adLocation'),
                    position: adLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onTap: (_) => onDirectionsTap(),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: GestureDetector(
                onTap: onDirectionsTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.directions, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'الاتجاهات عبر خرائط جوجل',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
