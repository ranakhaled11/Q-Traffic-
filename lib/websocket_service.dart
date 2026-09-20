import 'dart:async';
import 'dart:convert';
import 'server_config.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus {
disconnected,
connecting,
connected,
error,
}

class WebSocketService extends ChangeNotifier {
// =====================================================
// SERVER
// =====================================================

  String _url = "";



// =====================================================
// SOCKET
// =====================================================

WebSocketChannel? _channel;

StreamSubscription? _subscription;

// =====================================================
// STATUS
// =====================================================

ConnectionStatus _status =
ConnectionStatus.disconnected;

ConnectionStatus get status => _status;

// =====================================================
// STREAM
// =====================================================

final StreamController<Map<String, dynamic>>
_messageController =
StreamController<Map<String, dynamic>>.broadcast();

Stream<Map<String, dynamic>> get messages =>
_messageController.stream;

// =====================================================
// ERROR
// =====================================================

String? _lastError;

String? get lastError => _lastError;

// =====================================================
// CONNECT
// =====================================================

Future<void> connect() async {
  _url = await ServerConfig.getWebSocketUrl();

if (_status ==
ConnectionStatus.connected) {
debugPrint("[WS] Already connected");
return;
}

_setStatus(ConnectionStatus.connecting);

debugPrint("=================================");
debugPrint("[WS] CONNECTING...");
debugPrint("[WS] URL = $_url");
debugPrint("=================================");

try {
_channel = WebSocketChannel.connect(
Uri.parse(_url),
);

await _channel!.ready;

debugPrint("[WS] SOCKET READY");

_subscription = _channel!.stream.listen(
(rawMessage) {
debugPrint("=================================");
debugPrint("[WS] RAW MESSAGE:");
debugPrint(rawMessage);
debugPrint("=================================");

try {
final data = jsonDecode(
rawMessage as String,
) as Map<String, dynamic>;

debugPrint("[WS] PARSED:");
debugPrint(data.toString());

_messageController.add(data);
} catch (e) {
debugPrint("[WS] JSON PARSE ERROR");
debugPrint(e.toString());
}
},
onError: (error) {
_lastError = error.toString();

debugPrint("=================================");
debugPrint("[WS ERROR]");
debugPrint(error.toString());
debugPrint("=================================");

_setStatus(ConnectionStatus.error);
},
onDone: () {
debugPrint("=================================");
debugPrint("[WS CLOSED]");
debugPrint("=================================");

_setStatus(
ConnectionStatus.disconnected,
);
},
);

_setStatus(ConnectionStatus.connected);

debugPrint("=================================");
debugPrint(
"[WS CONNECTED SUCCESSFULLY]",
);
debugPrint("=================================");
} catch (e) {
_lastError = e.toString();

debugPrint("=================================");
debugPrint(
"[WS CONNECTION FAILED]",
);
debugPrint(e.toString());
debugPrint("=================================");

_setStatus(ConnectionStatus.error);
}
}

// =====================================================
// SEND
// =====================================================

void send(
Map<String, dynamic> message,
) {
if (_status !=
ConnectionStatus.connected) {
debugPrint("[WS] Cannot send");
debugPrint("[WS] Not connected");
return;
}

try {
final encoded =
jsonEncode(message);

debugPrint("=================================");
debugPrint("[WS SEND]");
debugPrint(encoded);
debugPrint("=================================");

_channel!.sink.add(encoded);
} catch (e) {
debugPrint("[WS SEND ERROR]");
debugPrint(e.toString());
}
}

// =====================================================
// REQUESTS
// =====================================================

void ping() {
send({
"type": "ping",
});
}

void getTrafficStatus() {
debugPrint(
"[WS] REQUESTING TRAFFIC STATUS",
);

send({
"type": "get_traffic_status",
});
}

void requestEmergencyRoute({
required String start,
required String end,
}) {
send({
"type": "emergency_route",
"start": start,
"end": end,
});
}

// =====================================================
// STATUS
// =====================================================

void _setStatus(
ConnectionStatus s,
) {
_status = s;

notifyListeners();

debugPrint(
"[WS STATUS] => $s",
);
}

// =====================================================
// DISCONNECT
// =====================================================

void disconnect() {
debugPrint(
"[WS] DISCONNECTING",
);

_subscription?.cancel();

_channel?.sink.close();

_setStatus(
ConnectionStatus.disconnected,
);
}

// =====================================================
// DISPOSE
// =====================================================

@override
void dispose() {
disconnect();

_messageController.close();

super.dispose();
}
}

