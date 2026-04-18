import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ run only once
    if (!started) {
      started = true;
      _startFlow();
    }
  }

  Future<void> _startFlow() async {
    // Step 1 → Accepted
    await Future.delayed(const Duration(seconds: 3));

    final query = await FirebaseFirestore.instance
        .collection('emergency_requests')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({"status": "Accepted"});
    }

    // Step 2 → Completed
    await Future.delayed(const Duration(seconds: 4));

    final query2 = await FirebaseFirestore.instance
        .collection('emergency_requests')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (query2.docs.isNotEmpty) {
      await query2.docs.first.reference.update({"status": "Completed"});
    }
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
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}