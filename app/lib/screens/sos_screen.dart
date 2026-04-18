import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SOSScreen extends StatelessWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 25),
        ),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final autoPolice = prefs.getBool("autoPolice") ?? true;

          if (autoPolice) {
            await FirebaseFirestore.instance
                .collection('emergency_requests')
                .add({
              "type": "Police SOS",
              "name": "SOS User",
              "phone": "N/A",
              "status": "Pending",
              "timestamp": FieldValue.serverTimestamp(),
              "userId": FirebaseAuth.instance.currentUser!.uid,
              "userLocationName": "Emergency Location",
              "userLat": 28.6280,
              "userLng": 77.3649,
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🚨 SOS Triggered")),
          );
        },
        child: const Text(
          "SOS",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}