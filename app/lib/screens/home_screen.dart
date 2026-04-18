import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSendingSOS = false;

  Future<void> triggerSOS() async {
    if (isSendingSOS) return;

    setState(() {
      isSendingSOS = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // for now, even if settings are empty, SOS should still work
      final autoPolice = prefs.getBool("autoPolice") ?? true;

      if (!autoPolice) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Auto police request is disabled in SOS settings")),
        );
        setState(() {
          isSendingSOS = false;
        });
        return;
      }

      final docRef = await FirebaseFirestore.instance
          .collection('emergency_requests')
          .add({
        "type": "Police SOS",
        "name": "SOS User",
        "phone": "N/A",
        "status": "Pending",
        "timestamp": FieldValue.serverTimestamp(),
        "userId": FirebaseAuth.instance.currentUser!.uid,
        "userLocationName": "Sector 62, Noida",
        "userLat": 28.6280,
        "userLng": 77.3649,
        "assignedServiceName": "Police Unit (Auto Assigned)",
        "assignedServiceType": "Police",
        "assignedServicePhone": "100",
        "assignedServiceLat": 28.6295,
        "assignedServiceLng": 77.3620,
      });

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/requestSent',
        arguments: {
          "docId": docRef.id,
          "type": "Police SOS",
          "name": "SOS User",
          "phone": "N/A",
          "userLocationName": "Sector 62, Noida",
          "assignedServiceName": "Police Unit (Auto Assigned)",
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SOS failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSendingSOS = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "🚨 Emergency App",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text("Your Location: Sector 62, Noida"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(
                horizontal: 60,
                vertical: 24,
              ),
            ),
            onPressed: isSendingSOS ? null : triggerSOS,
            child: isSendingSOS
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "SOS",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 18,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/emergency');
            },
            child: const Text(
              "Report Emergency",
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}