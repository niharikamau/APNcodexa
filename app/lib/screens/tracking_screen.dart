import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final docId = args["docId"] as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Request Tracking")),
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
          final status = data["status"] ?? "Pending";

          final userLocationName = data["userLocationName"] ?? "Unknown";
          final userLat = data["userLat"]?.toString() ?? "-";
          final userLng = data["userLng"]?.toString() ?? "-";

          final assignedServiceName =
              data["assignedServiceName"] ?? "Not assigned";
          final assignedServicePhone =
              data["assignedServicePhone"] ?? "Not available";
          final assignedServiceType = data["assignedServiceType"] ?? "Unknown";
          final assignedServiceLat =
              data["assignedServiceLat"]?.toString() ?? "-";
          final assignedServiceLng =
              data["assignedServiceLng"]?.toString() ?? "-";

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildStep("Request Sent", true),
                buildStep(
                  "Help Assigned",
                  (data["assignedServiceName"] != null &&
                          data["assignedServiceName"].toString().isNotEmpty) ||
                      status == "Accepted" ||
                      status == "Completed",
                ),
                buildStep("Incident Resolved", status == "Completed"),
                const SizedBox(height: 20),
                const Text(
                  "User Location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text("$userLocationName"),
                Text("Lat: $userLat, Lng: $userLng"),
                const SizedBox(height: 20),
                const Text(
                  "Assigned Service",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text("Name: $assignedServiceName"),
                Text("Type: $assignedServiceType"),
                Text("Phone: $assignedServicePhone"),
                Text("Lat: $assignedServiceLat, Lng: $assignedServiceLng"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildStep(String title, bool isDone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? Colors.green : Colors.grey,
            ),
            Container(height: 40, width: 2, color: Colors.grey),
          ],
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDone ? Colors.green : Colors.grey,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
