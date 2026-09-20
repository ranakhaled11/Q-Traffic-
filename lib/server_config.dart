import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const int webSocketPort = 8765;
  static const int apiPort = 8080;

  static Future<String> getIp() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("server_ip") ??
        "192.168.0.82";
  }

  static Future<String> getWebSocketUrl() async {
    final ip = await getIp();
    return "ws://$ip:$webSocketPort";
  }

  static Future<String> getPredictUrl() async {
    final ip = await getIp();
    return "http://$ip:$apiPort/predict";
  }

  static Future<String> getEtaUrl() async {
    final ip = await getIp();
    return "http://$ip:$apiPort/eta_osm";
  }
}