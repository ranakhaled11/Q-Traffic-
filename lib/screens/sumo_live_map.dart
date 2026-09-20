import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class SumoLiveMap extends StatefulWidget {
  const SumoLiveMap({super.key});

  @override
  State<SumoLiveMap> createState() => _SumoLiveMapState();
}

class _SumoLiveMapState extends State<SumoLiveMap> {

  List vehicles = [];

  bool _isDisposed = false;

  final String url = "http://192.168.0.111:8001/traffic";

  @override
  void initState() {
    super.initState();

    loadCars();
  }

  Future<void> loadCars() async {

    if (_isDisposed) return;

    try {

      final response = await http.get(Uri.parse(url));

      if (_isDisposed) return;

      final data = jsonDecode(response.body);

      setState(() {
        vehicles = data["vehicles"] ?? [];
      });

      print("🚗 Cars: ${vehicles.length}");

    } catch (e) {

      print("❌ ERROR: $e");
    }

    if (!_isDisposed) {
      Future.delayed(
        const Duration(seconds: 1),
        loadCars,
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }


  bool _isValid(dynamic value) {
    if (value == null) return false;
    final v = double.tryParse(value.toString());
    if (v == null) return false;
    return !v.isNaN && !v.isInfinite;
  }

  @override
  Widget build(BuildContext context) {

    final validVehicles = vehicles.where((v) {
      return _isValid(v["lat"]) && _isValid(v["lng"]);
    }).toList();

    return FlutterMap(

      options: const MapOptions(

        initialCenter: LatLng(29.973, 31.275),

        initialZoom: 14,

        interactionOptions: InteractionOptions(
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

          markers: validVehicles.map((v) {

            final lat = double.parse(v["lat"].toString());
            final lng = double.parse(v["lng"].toString());

            return Marker(

              point: LatLng(lat, lng),

              width: 40,
              height: 40,

              child: const Icon(
                Icons.local_taxi,
                color: Colors.red,
                size: 28,
              ),
            );

          }).toList(),
        ),
      ],
    );
  }
}