import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'status_screen.dart';
import 'profile_screen.dart';
import 'sos_settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreen(),
    const StatusScreen(),
    const SOSSettingsScreen(),
    const ProfileScreen(),
  ];

  String getTitle() {
    switch (currentIndex) {
      case 0:
        return "Home";
      case 1:
        return "Requests";
      case 2:
        return "SOS Settings";
      case 3:
        return "Profile";
      default:
        return "Emergency App";
    }
  }

  Widget drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTitle()),
        elevation: 0,
      ),

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.red,
                      size: 46,
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Emergency Response",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Manage incidents and profile information.",
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              drawerTile(
                icon: Icons.folder_copy_outlined,
                title: "Incidents",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/incidentList');
                },
              ),

              drawerTile(
                icon: Icons.edit_outlined,
                title: "Edit Profile",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/editProfile');
                },
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Response system prototype",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: screens[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: "Requests",
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning),
            label: "SOS",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}