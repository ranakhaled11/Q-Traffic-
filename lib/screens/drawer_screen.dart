import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'traffic_monitoring.dart';
import 'ambulance_map_screen.dart';
import 'signin_screen.dart';
import 'package:app/ServerSettingsPage.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});


  String getUserName(String? email) {
    if (email == null) return "User";

    String name = email.split("@").first;

    // take only letters before any number appears
    name = name.split(RegExp(r'\d')).first;

    return name.isEmpty ? "User" : name;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = getUserName(user?.email);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(45),
          bottomRight: Radius.circular(45),
        ),
      ),
      child: Column(
        children: [


          Container(
            padding: const EdgeInsets.only(
              top: 70,
              bottom: 90,
              left: 20,
              right: 16,
            ),
            color: const Color(0xFF2D2D2D),

            child: Row(
              children: [


                const CircleAvatar(
                  radius: 23,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: Color(0xFF0A1A3A),
                  ),
                ),

                const SizedBox(width: 10),


                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      user?.email ?? "No email",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),


          Expanded(
            child: ListView(
              padding: EdgeInsets.all(5),
              children: [

                _buildDrawerItem(
                  icon: Icons.local_hospital_outlined,
                  title: "Ambulance Map",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const AmbulanceMapScreen(),
                      ),
                    );
                  },
                ),


                _buildDrawerItem(
                  icon: Icons.map_outlined,
                  title: "Smart Monitoring",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const TrafficMonitoring(),
                      ),
                    );
                  },
                ),

    _buildDrawerItem(
    icon: Icons.settings_ethernet,
    title: "Server Settings",
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => const ServerSettingsPage(),
    ),
    );
    },
    ),

    const Divider(),




    ],
            ),
          ),

          const Divider(),


          Padding(
            padding: const EdgeInsets.only(left: 10,top: 8),
            child: _buildDrawerItem(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.black,
              onTap: () async {
                await FirebaseAuth.instance.signOut();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SignInScreen(),
                  ),
                      (route) => false,
                );
              },
            ),
          ),

          const SizedBox(height: 35),
        ],
      ),
    );
  }

  static Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}