import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  String normalizeStatus(dynamic rawStatus) {
    if (rawStatus == null) return "pending";
    return rawStatus.toString().trim().toLowerCase();
  }

  String prettyStatus(String status) {
    if (status == "on the way") return "On The Way";
    if (status.isEmpty) return "Pending";
    return status[0].toUpperCase() + status.substring(1);
  }

  Color getStatusColor(String status) {
    if (status == "pending") return Colors.orange;
    if (status == "assigned") return Colors.blue;
    if (status == "on the way") return Colors.purple;
    if (status == "resolved") return Colors.green;
    return Colors.grey;
  }

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
          if (snapshot.hasError) {
            return Center(
              child: Text("Something went wrong: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Request not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = normalizeStatus(data["status"]);
          final statusColor = getStatusColor(status);

          final location = data["location"] as Map<String, dynamic>?;
          final lat = location?["latitude"]?.toString() ?? "-";
          final lng = location?["longitude"]?.toString() ?? "-";

          final assignedDriver =
              data["assignedDriver"] ??
              data["assignedServiceName"] ??
              "Not assigned";

          final assignedPhone =
              data["assignedPhone"] ??
              data["servicePhone"] ??
              data["phone"] ??
              "-";

          final vehicleType =
              data["vehicleType"] ??
              data["serviceType"] ??
              "-";

          final distance = data["distance"]?.toString() ?? "-";

          final helpAssigned =
              assignedDriver.toString() != "Not assigned" ||
              status == "assigned" ||
              status == "on the way" ||
              status == "resolved";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Status: ${prettyStatus(status)}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 20),

                buildStep("Request Sent", true),
                buildStep("Help Assigned", helpAssigned),
                buildStep(
                  "On The Way",
                  status == "on the way" || status == "resolved",
                ),
                buildStep(
                  "Incident Resolved",
                  status == "resolved",
                ),

                const SizedBox(height: 25),

                const Text(
                  "User Location",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Lat: $lat, Lng: $lng"),

                const SizedBox(height: 25),

                const Text(
                  "Assigned Service",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Assigned Driver: $assignedDriver"),
                Text("Phone: $assignedPhone"),
                Text("Vehicle Type: $vehicleType"),
                Text("Distance: $distance"),
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
            Container(
              height: 40,
              width: 2,
              color: Colors.grey,
            ),
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