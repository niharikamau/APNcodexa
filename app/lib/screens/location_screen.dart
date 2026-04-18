import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String status = "Searching nearest help...";

  @override
  void initState() {
    super.initState();

    // UI message update
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        status = "Help is on the way 🚑";
      });
    });

    // Step 1: Pending → Accepted
    Future.delayed(const Duration(seconds: 3), () async {
      final query = await FirebaseFirestore.instance
          .collection('emergency_requests')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          "status": "Accepted",
        });
      }
    });

    // Step 2: Accepted → Completed
    Future.delayed(const Duration(seconds: 7), () async {
      final query = await FirebaseFirestore.instance
          .collection('emergency_requests')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          "status": "Completed",
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    String type = "Unknown";
    String name = "User";
    String phone = "N/A";

    if (args is Map) {
      type = args["type"] ?? "Unknown";
      name = args["name"] ?? "User";
      phone = args["phone"] ?? "N/A";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Your Location")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Emergency: $type",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text(
              "Name: $name\nPhone: $phone",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(),
            const SizedBox(height: 20),

            Text(
              status,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}