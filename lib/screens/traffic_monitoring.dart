import 'dart:async';
import 'drawer_screen.dart';
import 'package:flutter/material.dart';

import 'package:app/websocket_service.dart';
import 'full_map_screen.dart';
import 'osm_map.dart';

class TrafficMonitoring extends StatefulWidget {
  const TrafficMonitoring({super.key});

  @override
  State<TrafficMonitoring> createState() =>
      _TrafficMonitoringState();
}

class _TrafficMonitoringState
    extends State<TrafficMonitoring> {

  List vehicles = [];
  List intersections = [];
  int totalVehicles = 0;

  final WebSocketService ws = WebSocketService();

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  Future<void> connectSocket() async {

    await ws.connect();

    _subscription = ws.messages.listen((data) {

      print("LIVE DATA:");
      print(data);

      if (data["type"] == "traffic_update") {
        setState(() {
          vehicles = data["vehicles"] ?? [];
          intersections = data["intersections"] ?? [];
          totalVehicles = data["total_vehicles"] ?? 0;
        });
      }
    });

    ws.getTrafficStatus();
  }


  Color getStateColor(String state) {
    switch (state) {
      case "CONGESTED":
        return Colors.red;
      case "MEDIUM":
        return Colors.deepOrange;
      case "LIGHT":
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }


  Map<String, dynamic>? getWorst() {
    if (intersections.isEmpty) return null;
    intersections.sort(
          (a, b) => (b["score"] ?? 0).compareTo(a["score"] ?? 0),
    );
    return Map<String, dynamic>.from(intersections.first);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    ws.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final worst = getWorst();

    return Scaffold(
        drawer: const DrawerScreen(),
      backgroundColor: Colors.white,

        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,

          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),

          title: const Text(
            "Traffic Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

      body: SingleChildScrollView(

        child: Padding(

          padding: const EdgeInsets.all(18),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [



              Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.black,
                    ),
                    clipBehavior: Clip.antiAlias,


                    child: OsmMap(
                      markers: vehicles,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FullMapScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),



              Row(
                children: [
                  _statCard(
                    title: "Vehicles",
                    value: totalVehicles.toString(),
                    icon: Icons.local_taxi,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    title: "Intersections",
                    value: intersections.length.toString(),
                    icon: Icons.route,
                    color: Colors.black,
                  ),
                ],
              ),

              const SizedBox(height: 20),



              if (worst != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: getStateColor(
                      worst["state"] ?? "",
                    ).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Worst Intersection",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("ID: ${worst["id"]}"),
                            Text(
                              "Score: ${worst["score"]} | AI: ${worst["green_time"] != null ? '${worst["green_time"]}s' : 'Calculating...'}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              const Text(
                "Live Intersections",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),



              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: intersections.length,
                itemBuilder: (context, i) {

                  final inter =
                  Map<String, dynamic>.from(intersections[i]);

                  final color = getStateColor(inter["state"] ?? "");

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          "Intersection ${inter["id"]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [

                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                _infoBox(
                                  title: "Score",
                                  value: (inter["score"] ?? 0).toString(),
                                  icon: Icons.analytics,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 10),
                                _infoBox(
                                  title: "AI Time",
                                  value: inter["green_time"] != null
                                      ? "${inter["green_time"]}s"
                                      : "...",
                                  icon: Icons.smart_toy,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _mini(
                                "Cars",
                                (inter["cars"] ?? 0).toString(),
                              ),
                              _mini(
                                "Speed",
                                "${inter["speed"] ?? 0} m/s",
                              ),
                              _mini(
                                "Wait",
                                "${inter["wait"] ?? 0} s",
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String t, String v) {
    return Column(
      children: [
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(t),
      ],
    );
  }
}