import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class SmartMap extends StatefulWidget {

  final List vehicles;

  const SmartMap({
    super.key,
    required this.vehicles,
  });

  @override
  State<SmartMap> createState() => _SmartMapState();
}

class _SmartMapState extends State<SmartMap> {

  MapLibreMapController? controller;

  final Map<String, Symbol> symbols = {};

  @override
  Widget build(BuildContext context) {

    return MapLibreMap(

      styleString:
      "https://demotiles.maplibre.org/style.json",

      initialCameraPosition: const CameraPosition(

        target: LatLng(
          29.9602,
          31.2569,
        ),

        zoom: 14,
      ),

      onMapCreated: (c) {

        controller = c;

        updateVehicles();
      },
    );
  }


  Future<void> updateVehicles() async {

    if (controller == null) return;

    for (var v in widget.vehicles) {

      final id = v["id"];

      final lat = v["lat"];
      final lng = v["lng"];

      if (lat == null || lng == null) {
        continue;
      }


      if (symbols.containsKey(id)) {

        await controller!.updateSymbol(

          symbols[id]!,

          SymbolOptions(
            geometry: LatLng(lat, lng),
          ),
        );

      } else {


        final symbol =
        await controller!.addSymbol(

          SymbolOptions(

            geometry: LatLng(lat, lng),

            iconImage: "car-15",

            iconSize: 1.5,
          ),
        );

        symbols[id] = symbol;
      }
    }
  }

  @override
  void didUpdateWidget(covariant SmartMap oldWidget) {

    super.didUpdateWidget(oldWidget);

    updateVehicles();
  }
}