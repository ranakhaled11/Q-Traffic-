import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() =>
      _ServerSettingsPageState();
}

class _ServerSettingsPageState
    extends State<ServerSettingsPage> {

  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {

    final prefs =
    await SharedPreferences.getInstance();

    _ipController.text =
        prefs.getString("server_ip") ??
            "192.168.0.82";

    _portController.text =
        (prefs.getInt("server_port") ?? 8765)
            .toString();
  }

  Future<void> _save() async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      "server_ip",
      _ipController.text.trim(),
    );

    await prefs.setInt(
      "server_port",
      int.parse(_portController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Saved Successfully"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        const Text("Server Settings"),
      ),

      body: Padding(

        padding:
        const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(

              controller: _ipController,

              decoration:
              const InputDecoration(

                labelText: "Server IP",

                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(

              controller:
              _portController,

              keyboardType:
              TextInputType.number,

              decoration:
              const InputDecoration(

                labelText: "Port",

                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,

              height: 50,

              child: ElevatedButton(

                onPressed: _save,

                child: const Text(
                  "Save",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}