import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final docId = args["docId"] as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Request not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final type = data["type"] ?? "Unknown";
          final name = data["name"] ?? "User";
          final phone = data["phone"] ?? "N/A";
          final status = data["status"] ?? "Pending";

          final isResolved = status == "Completed";

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  isResolved ? Icons.check_circle : Icons.warning,
                  color: isResolved ? Colors.green : Colors.orange,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  isResolved ? "Incident Resolved" : "Emergency Active",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text("Type: $type"),
                Text("Name: $name"),
                Text("Phone: $phone"),
                Text("Status: $status"),
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
                  child: const Text("Details"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}