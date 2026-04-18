import 'package:flutter/material.dart';

class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final type = args?["type"] ?? "Unknown";
    final name = args?["name"] ?? "User";
    final phone = args?["phone"] ?? "N/A";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Sent"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),

            const SizedBox(height: 20),

            const Text(
              "Emergency Report Sent",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text("Type: $type"),
            Text("Name: $name"),
            Text("Phone: $phone"),

            const SizedBox(height: 30),

            const Text("Help is on the way 🚑"),
          ],
        ),
      ),
    );
  }
}