import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:app/server_config.dart';
import 'map_ui.dart';

class Screen3 extends StatefulWidget {
  final latlng.LatLng startLatLng;
  final String startAddress;
  final latlng.LatLng destLatLng;
  final String destAddress;

  const Screen3({
    super.key,
    required this.startLatLng,
    required this.startAddress,
    required this.destLatLng,
    required this.destAddress,
  });

  @override
  State<Screen3> createState() => _Screen3State();
}

class _Screen3State extends State<Screen3> {

  final MapController mapController = MapController();

  String quantumUrl = "";
  String etaUrl = "";

  String etaText = "Calculating...";
  bool isLoading = true;

  final List<latlng.LatLng> routeLatLngs = [];

  bool started = false;

  StreamSubscription<Position>? _posSub;
  bool _following = false;

  latlng.LatLng? currentLocation;

  @override
  void initState() {
    super.initState();

    debugPrint(
        "start = ${widget.startLatLng.latitude}, ${widget.startLatLng.longitude}");

    debugPrint(
        "dest = ${widget.destLatLng.latitude}, ${widget.destLatLng.longitude}");

    _initialize();
  }

  Future<void> _initialize() async {

    quantumUrl = await ServerConfig.getPredictUrl();
    etaUrl = await ServerConfig.getEtaUrl();

    debugPrint("Quantum URL = $quantumUrl");
    debugPrint("ETA URL = $etaUrl");

    await _loadRouteFromBackend();
  }

  @override
  void dispose() {
    _stopFollowing();
    super.dispose();
  }

  Future<void> _loadRouteFromBackend() async {
    setState(() {
      isLoading = true;
      etaText = "Calculating...";
      routeLatLngs.clear();
    });

    try {
      final body = jsonEncode({
        "start_lat": widget.startLatLng.latitude,
        "start_lng": widget.startLatLng.longitude,
        "end_lat": widget.destLatLng.latitude,
        "end_lng": widget.destLatLng.longitude,
      });

      final predictRes = await http
          .post(
        Uri.parse(quantumUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      )
          .timeout(const Duration(seconds: 60));

      debugPrint("Predict status: ${predictRes.statusCode}");
      debugPrint("Predict body: ${predictRes.body}");

      if (!mounted) return;

      /*final etaRes = await http.post(
        Uri.parse(etaUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      )
          .timeout(const Duration(seconds: 60));

      debugPrint("ETA status: ${etaRes.statusCode}");
      debugPrint("ETA body: ${etaRes.body}");

      String minutesStr = "Unavailable";

      if (etaRes.statusCode == 200) {
        final etaData = json.decode(etaRes.body);
        debugPrint("ETA JSON = $etaData");
        if (etaData["eta_minutes"] != null) {
          final minutes =
          (etaData["eta_minutes"] as num).toDouble();

          if (minutes.isFinite) {
            minutesStr = "${minutes.toStringAsFixed(1)} min";
          }
        }
      }
*/

      if (predictRes.statusCode == 200) {
        final predData = json.decode(predictRes.body);

        final List<dynamic>? pts =
        predData["polyline"];

        if (pts != null && pts.isNotEmpty) {
          for (final p in pts) {
            final lat = (p["lat"] as num).toDouble();
            final lng = (p["lng"] as num).toDouble();

            if (!lat.isFinite || !lng.isFinite) {
              debugPrint("Invalid point: lat=$lat lng=$lng");
              continue;
            }

            routeLatLngs.add(
              latlng.LatLng(lat, lng),
            );
          }
        }
        debugPrint("Polyline count = ${routeLatLngs.length}");
      }

      setState(() {
        etaText = "";
        isLoading = false;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _fitToRoute();
        }
      });
    } catch (e, s) {
      debugPrint("ERROR: $e");
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        etaText = "Unavailable";
        isLoading = false;
      });
    }
  }

  void _fitToRoute() {
    if (routeLatLngs.isEmpty) {
      mapController.move(widget.startLatLng, 13);
      return;
    }

    for (final p in routeLatLngs) {
      if (!p.latitude.isFinite || !p.longitude.isFinite) {
        return;
      }
    }

    double minLat = routeLatLngs.first.latitude;
    double maxLat = routeLatLngs.first.latitude;
    double minLng = routeLatLngs.first.longitude;
    double maxLng = routeLatLngs.first.longitude;

    for (final p in routeLatLngs) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      latlng.LatLng(minLat, minLng),
      latlng.LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(90),
      ),
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled =
    await Geolocator.isLocationServiceEnabled();

    if (!enabled) return false;

    LocationPermission perm =
    await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm =
      await Geolocator.requestPermission();
    }

    if (perm ==
        LocationPermission.denied ||
        perm ==
            LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void _stopFollowing() {
    _following = false;
    _posSub?.cancel();
    _posSub = null;
  }

  Future<void> _startFollowing() async {
    if (_following) return;

    final ok =
    await _ensureLocationPermission();

    if (!ok) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Enable location permission/service",
          ),
        ),
      );

      return;
    }

    _following = true;

    final first =
    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    _animateToPosition(first);

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _posSub?.cancel();

    _posSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((pos) {
      if (!_following) return;

      _animateToPosition(pos);
    });
  }

  void _animateToPosition(Position pos) {
    if (!pos.latitude.isFinite ||
        !pos.longitude.isFinite) {
      return;
    }
    final target = latlng.LatLng(
      pos.latitude,
      pos.longitude,
    );

    currentLocation = target;

    mapController.move(target, 17.5);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleStartStop() async {
    if (!started) {
      setState(() => started = true);

      await _startFollowing();
    } else {
      _stopFollowing();

      setState(() => started = false);

      _fitToRoute();
    }
  }

  String _safe(String s) =>
      s.trim().isEmpty ? "—" : s.trim();

  @override
  Widget build(BuildContext context) {
    final startText =
    _safe(widget.startAddress);

    final destText =
    _safe(widget.destAddress);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.startLatLng,
              initialZoom: 13,
            ),
            children: [
        TileLayer(
        urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      ),


              if (routeLatLngs.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeLatLngs,
                      strokeWidth: 6,
                      color: Colors.black,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  if (widget.destLatLng.latitude.isFinite &&
                      widget.destLatLng.longitude.isFinite)
                    Marker(
                      point: widget.destLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 38,
                      ),
                    ),

                  if (currentLocation != null)
                    Marker(
                      point: currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                ],
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
                  child: MapIconButton(
                    icon: Icons.arrow_back,
                    onTap: () {
                      _stopFollowing();
                      Navigator.pop(context);
                    },
                    size: 22,
                    weight: 900,
                  ),
                ),

                const Spacer(),

                MapGlassPill(
                  child: MapIconButton(
                    icon:
                    Icons.center_focus_strong,
                    onTap: () {
                      if (started) {
                        _startFollowing();
                      } else {
                        _fitToRoute();
                      }
                    },
                    size: 20,
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
                    Row(
                      children: [
                        Text(
                          started
                              ? "Navigation"
                              : "Route",
                          style:
                          AddressTextStyle
                              .title,
                        ),

                        const Spacer(),

                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Text(
                            etaText,
                            style:
                            AddressTextStyle
                                .meta,
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    AddressLine(
                      label: "From",
                      content: Text(
                        startText,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        AddressTextStyle
                            .value,
                      ),
                    ),

                    const SizedBox(height: 8),

                    AddressLine(
                      label: "To",
                      content: Text(
                        destText,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        AddressTextStyle
                            .value,
                      ),
                    ),

                    const SizedBox(height: 14),

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
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        onPressed:
                        _toggleStartStop,
                        child: Text(
                          started
                              ? "Stop"
                              : "Start",
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontWeight:
                            FontWeight
                                .w800,
                            fontSize: 14,
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