import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'drawer_screen.dart';
import 'map_ui.dart';
import 'emergency_route.dart';

class AmbulanceMapScreen extends StatefulWidget {
  const AmbulanceMapScreen({super.key});

  @override
  State<AmbulanceMapScreen> createState() =>
      _AmbulanceMapScreenState();
}

class _AmbulanceMapScreenState
    extends State<AmbulanceMapScreen> {
  final MapController mapController = MapController();

  latlng.LatLng? pickupLatLng;
  latlng.LatLng? destinationLatLng;

  String pickupAddress = "Detecting location...";
  String destinationAddress = "Enter destination";

  bool pickPickupFromMap = false;
  bool pickDestFromMap = false;

  Timer? _debounce;

  final TextEditingController _searchController =
  TextEditingController();

  List<dynamic> suggestions = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      setState(() {
        pickupAddress = "Location service disabled";
      });
      return;
    }

    var permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(
            () => pickupAddress = "Location permission denied",
      );
      return;
    }

    final pos =
    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    pickupLatLng =
        latlng.LatLng(pos.latitude, pos.longitude);

    pickupAddress =
    await _reverseGeocodeOrCoords(
      pickupLatLng!,
    );

    if (!mounted) return;
    setState(() {});
    _moveCamera(pickupLatLng!, 16);
  }

  Future<String> _reverseGeocodeOrCoords(
      latlng.LatLng latLng,
      ) async {
    try {
      final placemarks =
      await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isEmpty) {
        return "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
      }

      final p = placemarks.first;

      final parts = <String>[
        if ((p.name ?? "").trim().isNotEmpty)
          p.name!.trim(),
        if ((p.street ?? "").trim().isNotEmpty)
          p.street!.trim(),
        if ((p.subLocality ?? "").trim().isNotEmpty)
          p.subLocality!.trim(),
        if ((p.locality ?? "").trim().isNotEmpty)
          p.locality!.trim(),
        if ((p.administrativeArea ?? "")
            .trim()
            .isNotEmpty)
          p.administrativeArea!.trim(),
        if ((p.country ?? "").trim().isNotEmpty)
          p.country!.trim(),
      ];

      final unique = <String>[];

      for (final s in parts) {
        if (!unique.contains(s)) {
          unique.add(s);
        }
      }

      final text =
      unique.join(", ").trim();

      return text.isEmpty
          ? "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}"
          : text;
    } catch (_) {
      return "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
    }
  }

  void _moveCamera(
      latlng.LatLng target,
      double zoom,
      ) {
    mapController.move(target, zoom);
  }

  void _goToMyLocation() {
    if (pickupLatLng != null) {
      _moveCamera(pickupLatLng!, 16);
    }
  }

  Future<void> _setPickup(
      latlng.LatLng latLng,
      ) async {
    pickupLatLng = latLng;

    pickupAddress =
    await _reverseGeocodeOrCoords(latLng);

    if (mounted) setState(() {});
  }

  Future<void> _setDestination(
      latlng.LatLng latLng, {
        String? label,
      }) async {
    destinationLatLng = latLng;

    destinationAddress =
        label ??
            await _reverseGeocodeOrCoords(
              latLng,
            );

    if (mounted) setState(() {});
  }

  void _onMapTap(
      latlng.LatLng latLng,
      ) async {
    if (pickPickupFromMap) {
      await _setPickup(latLng);
      if (!mounted) return;
      setState(
            () => pickPickupFromMap = false,
      );

      return;
    }

    if (pickDestFromMap) {
      await _setDestination(latLng);
      if (!mounted) return;
      setState(
            () => pickDestFromMap = false,
      );

      return;
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;

      setState(() => suggestions = []);
      return;
    }

    try {
      final url = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'jsonv2',
          'limit': '10',
          'accept-language': 'ar,en',
          'countrycodes': 'eg',
          'addressdetails': '1',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RanaApp/1.0 (rana@email.com)',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          suggestions = json.decode(response.body);
        });
      } else {
        setState(() {
          suggestions = [];
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        suggestions = [];
      });
    }
  }

  List<Marker> _markers() {
    final markers = <Marker>[];

    if (pickupLatLng != null) {
      markers.add(
        Marker(
          point: pickupLatLng!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.black,
            size: 38,
          ),
        ),
      );
    }

    if (destinationLatLng != null) {
      markers.add(
        Marker(
          point: destinationLatLng!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 38,
          ),
        ),
      );
    }

    return markers;
  }

  String _safe(String s) =>
      s.trim().isEmpty ? "—" : s.trim();

  @override
  Widget build(BuildContext context) {
    final canGo =
        pickupLatLng != null &&
            destinationLatLng != null;

    final fromText =
    _safe(pickupAddress);

    return Scaffold(
      drawer: const DrawerScreen(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: latlng.LatLng(30.0444, 31.2357),
              initialZoom: 12,
              onTap: (tapPosition, point) {
                _onMapTap(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: _markers(),
              ),
            ],
          ),
          Positioned(
            top: 44,
            left: 16,
            right: 16,
            child: Row(
              children: [
                MapGlassPill(
                  child: Builder(
                    builder: (context) =>
                        MapIconButton(
                          icon: Icons.menu,
                          onTap: () =>
                              Scaffold.of(
                                context,
                              ).openDrawer(),
                        ),
                  ),
                ),

                const Spacer(),

                MapGlassPill(
                  child: MapIconButton(
                    icon:
                    Icons.my_location,
                    onTap:
                    _goToMyLocation,
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment:
            Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: BottomCardShell(
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Text(
                          "Route",
                          style:
                          AddressTextStyle
                              .title,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    AddressLine(
                      label: "From",
                      content: Expanded(
                        child: Text(
                          fromText,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          AddressTextStyle
                              .value,
                        ),
                      ),
                      trailing:
                      IconButton(
                        tooltip:
                        "Pick pickup on map",
                        icon: Icon(
                          Icons
                              .edit_location_alt,
                          color:
                          pickPickupFromMap
                              ? Colors
                              .red
                              : AddressTextStyle
                              .ink,
                        ),
                        onPressed: () {
                          setState(() {
                            pickPickupFromMap =
                            !pickPickupFromMap;

                            pickDestFromMap =
                            false;
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    AddressLine(
                      label: "To",
                      content: Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller:
                              _searchController,
                              onChanged:
                                  (value) {
                                _debounce
                                    ?.cancel();

                                _debounce =
                                    Timer(
                                      const Duration(
                                        milliseconds:
                                        400,
                                      ),
                                          () {
                                        _searchPlaces(
                                          value,
                                        );
                                      },
                                    );
                              },
                              decoration:
                              InputDecoration(
                                hintText:
                                "Enter destination",
                                filled:
                                true,
                                fillColor:
                                Colors.grey
                                    .shade100,
                                isDense:
                                true,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  horizontal:
                                  12,
                                  vertical:
                                  12,
                                ),
                                border:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    14,
                                  ),
                                  borderSide:
                                  BorderSide
                                      .none,
                                ),
                              ),
                            ),

                            if (suggestions
                                .isNotEmpty)
                              Container(
                                margin:
                                const EdgeInsets.only(
                                  top: 6,
                                ),
                                constraints:
                                const BoxConstraints(
                                  maxHeight:
                                  180,
                                ),
                                decoration:
                                BoxDecoration(
                                  color:
                                  Colors
                                      .white,
                                  borderRadius:
                                  BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child:
                                ListView.builder(
                                  shrinkWrap:
                                  true,
                                  itemCount:
                                  suggestions
                                      .length,
                                  itemBuilder:
                                      (
                                      context,
                                      index,
                                      ) {
                                    final item =
                                    suggestions[index];

                                    return ListTile(
                                      title:
                                      Text(
                                        item['display_name'],
                                        maxLines:
                                        2,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style:
                                        const TextStyle(
                                          fontSize:
                                          13,
                                        ),
                                      ),
                                      onTap:
                                          () async {
                                        final lat = double.parse(
                                          item['lat'],
                                        );

                                        final lon = double.parse(
                                          item['lon'],
                                        );

                                        final address =
                                        item['display_name'];

                                        _searchController.text = address;

                                        await _setDestination(
                                          latlng.LatLng(lat, lon),
                                          label: address,
                                        );

                                        if (!mounted) return;

                                        setState(() {
                                          suggestions.clear();
                                        });

                                        _moveCamera(
                                          latlng.LatLng(lat, lon),
                                          15,
                                        );

                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing:
                      IconButton(
                        tooltip:
                        "Pick destination on map",
                        icon: Icon(
                          Icons
                              .edit_location_alt,
                          color:
                          pickDestFromMap
                              ? Colors
                              .red
                              : AddressTextStyle
                              .ink,
                        ),
                        onPressed: () {
                          setState(() {
                            pickDestFromMap =
                            !pickDestFromMap;

                            pickPickupFromMap =
                            false;
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    SizedBox(
                      width:
                      double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          AddressTextStyle
                              .ink,
                          disabledBackgroundColor:
                          AddressTextStyle
                              .ink
                              .withOpacity(
                            0.35,
                          ),
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        onPressed: canGo
                            ? () {

                          Navigator.push(

                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                  Screen3(
                                    startLatLng:
                                    pickupLatLng!,
                                    startAddress:
                                    pickupAddress,
                                    destLatLng:
                                    destinationLatLng!,
                                    destAddress:
                                    destinationAddress,
                                  ),
                            ),
                          );
                        }
                            : null,
                        child:
                        const Text(
                          "Route Directions",
                          style:
                          TextStyle(
                            color:
                            Colors
                                .white,
                            fontWeight:
                            FontWeight
                                .w800,
                            fontSize:
                            14,
                          ),
                        ),
                      ),
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