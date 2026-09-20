import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/websocket_service.dart';
import 'osm_map.dart';

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {

  List vehicles = [];

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
      if (data["type"] == "traffic_update") {
        setState(() {
          vehicles = data["vehicles"] ?? [];
        });
      }
    });
  }


  @override
  void dispose() {
    _subscription?.cancel();
    ws.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ✅ OsmMap مع vehicles من WebSocket
          Positioned.fill(
            child: OsmMap(
              markers: vehicles,
            ),
          ),

          // 🔙 Close button
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.close),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}