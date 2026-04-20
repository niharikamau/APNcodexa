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
    return Icons.warning_amber_rounded;
  }

  String prettyStatus(String status) {
    if (status == "on the way") return "On The Way";
    if (status.isEmpty) return "Pending";
    return status[0].toUpperCase() + status.substring(1);
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

          final serviceType =
              (data["serviceType"] ?? data["type"] ?? "unknown").toString();
          final user = (data["user"] ?? data["name"] ?? "Unknown").toString();
          final phone = (data["phone"] ?? "N/A").toString();

          final statusColor = getStatusColor(status);

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      getStatusIcon(status),
                      size: 80,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    getStatusTitle(status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        buildInfoRow("Service", serviceType),
                        buildInfoRow("User", user),
                        buildInfoRow("Phone", phone),
                        buildInfoRow("Status", prettyStatus(status)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/tracking',
                          arguments: {
                            "docId": docId,
                          },
                        );
                      },
                      child: const Text(
                        "View Details",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}