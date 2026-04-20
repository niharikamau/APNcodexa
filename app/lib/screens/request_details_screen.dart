import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key});

  String normalizeStatus(dynamic rawStatus) {
    if (rawStatus == null) return "pending";
    return rawStatus.toString().trim().toLowerCase();
  }

  Color getStatusColor(String status) {
    if (status == "pending") return Colors.orange;
    if (status == "assigned") return Colors.blue;
    if (status == "on the way") return Colors.purple;
    if (status == "resolved") return Colors.green;
    return Colors.grey;
  }

  String getStatusTitle(String status) {
    if (status == "resolved") return "Incident Resolved";
    if (status == "on the way") return "Responder On The Way";
    if (status == "assigned") return "Help Assigned";
    return "Emergency Active";
  }

  IconData getStatusIcon(String status) {
    if (status == "resolved") return Icons.check_circle;
    if (status == "on the way") return Icons.local_shipping;
    if (status == "assigned") return Icons.assignment_turned_in;
    return Icons.warning;
  }

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
          final status = normalizeStatus(data["status"]);

          final serviceType = data["serviceType"] ?? data["type"] ?? "unknown";
          final user = data["user"] ?? data["name"] ?? "Unknown";
          final phone = data["phone"] ?? "N/A";

          final statusColor = getStatusColor(status);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  getStatusIcon(status),
                  color: statusColor,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  getStatusTitle(status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text("Service Type: $serviceType"),
                Text("User: $user"),
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