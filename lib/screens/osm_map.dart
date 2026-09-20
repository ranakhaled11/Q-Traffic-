import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmMap extends StatelessWidget {

  final List markers;

  const OsmMap({
    super.key,
    required this.markers,
  });

  bool isValid(dynamic value) {

    if (value == null) return false;

    final v = double.tryParse(
      value.toString(),
    );

    if (v == null) return false;

    if (v.isNaN || v.isInfinite) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {



    final validMarkers = markers.where((m) {

      final lat = m["lat"];
      final lng = m["lng"];

      return isValid(lat) && isValid(lng);

    }).toList();



    if (validMarkers.isEmpty) {

      return const Center(

        child: Text(

          "No vehicle positions",

          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }


    final first = validMarkers.first;

    final center = LatLng(

      double.parse(first["lat"].toString()),
      double.parse(first["lng"].toString()),
    );

    return FlutterMap(

      options: MapOptions(

        initialCenter: center,

        initialZoom: 15,

        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),

      children: [



        TileLayer(

          urlTemplate:
          'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',

          userAgentPackageName: 'com.example.app',
        ),



        MarkerLayer(

          markers: validMarkers.map((m) {

            final lat = double.parse(
              m["lat"].toString(),
            );

            final lng = double.parse(
              m["lng"].toString(),
            );

            return Marker(

              point: LatLng(lat, lng),

              width: 7,
              height: 7,

              child: Container(

                width: 6,
                height: 6,

                decoration: const BoxDecoration(

                  color: Colors.black54,

                  shape: BoxShape.circle,
                ),
              ),
            );

          }).toList(),
        ),
      ],
    );
  }
}