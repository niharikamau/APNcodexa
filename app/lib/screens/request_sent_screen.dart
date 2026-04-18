import 'package:flutter/material.dart';

class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final docId = args?["docId"];
    final type = args?["type"] ?? "Unknown";
    final userLocationName = args?["userLocationName"] ?? "Unknown location";
    final assignedServiceName =
        args?["assignedServiceName"] ?? "Service not assigned";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Sent"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.check_circle, color: Colors.green, size: 90),
            const SizedBox(height: 20),
            const Text(
              "Emergency report sent.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text("Type: $type"),
            const SizedBox(height: 8),
            Text("Your Location: $userLocationName"),
            const SizedBox(height: 8),
            Text("Nearest Service Assigned: $assignedServiceName"),
            const SizedBox(height: 20),
            const Text(
              "Help is on the way 🚑",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/tracking',
                  arguments: {
                    "docId": docId,
                  },
                );
              },
              child: const Text("View Details"),
            ),
          ],
        ),
      ),
    );
  }
}