import 'package:flutter/material.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)?.settings.arguments as dynamic;

    final type = data["type"] ?? "Unknown";
    final name = data["name"] ?? "User";
    final phone = data["phone"] ?? "N/A";
    final status = data["status"] ?? "Pending";

    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              status == "Completed" ? Icons.check_circle : Icons.warning,
              color: status == "Completed" ? Colors.green : Colors.orange,
              size: 80,
            ),

            const SizedBox(height: 20),

            Text(
              status == "Completed" ? "Incident Resolved" : "Emergency Active",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text("Type: $type"),
            Text("Name: $name"),
            Text("Phone: $phone"),
            Text("Status: $status"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tracking', arguments: data);
              },
              child: const Text("Details"),
            ),
          ],
        ),
      ),
    );
  }
}
