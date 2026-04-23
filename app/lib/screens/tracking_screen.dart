import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  String normalizeStatus(dynamic rawStatus) {
    if (rawStatus == null) return "pending";
    return rawStatus.toString().trim().toLowerCase();
  }

  String prettyStatus(String status) {
    if (status == "on_the_way") return "On The Way";
    if (status.isEmpty) return "Pending";
    return status[0].toUpperCase() + status.substring(1);
  }

  Color getStatusColor(String status) {
    if (status == "pending") return Colors.orange;
    if (status == "assigned") return Colors.blue;
    if (status == "on_the_way") return Colors.purple;
    if (status == "resolved") return Colors.green;
    return Colors.grey;
  }

  Color getUrgencyColor(String urgency) {
    if (urgency == "critical") return Colors.red;
    if (urgency == "high") return Colors.orange;
    if (urgency == "medium") return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final docId = args["docId"] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Tracking"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
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
          final urgency = (data["urgency"] ?? "low").toString().toLowerCase();
          final status = normalizeStatus(data["status"]);

          final location = data["location"] as Map<String, dynamic>?;
          final lat = location?["latitude"]?.toString() ?? "-";
          final lng = location?["longitude"]?.toString() ?? "-";

          final assignedProviderName =
              data["assignedProviderName"] ?? "Not assigned";
          final assignedProviderPhone = data["assignedProviderPhone"] ?? "-";
          final assignedDistanceKm =
              data["assignedDistanceKm"]?.toString() ?? "-";
          final assignedProviderId = data["assignedProviderId"] ?? "-";
          final assignedProviderCollection =
              data["assignedProviderCollection"] ?? "-";

          final vehicleType = data["serviceType"] ?? "-";

          final helpAssigned =
              assignedProviderName.toString() != "Not assigned" ||
              status == "assigned" ||
              status == "on_the_way" ||
              status == "resolved";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "Current Status",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        prettyStatus(status),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: getUrgencyColor(urgency).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Urgency",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        urgency.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getUrgencyColor(urgency),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                buildStep("Request Sent", true),
                buildStep("Help Assigned", helpAssigned),
                buildStep(
                  "On The Way",
                  status == "on_the_way" || status == "resolved",
                ),
                buildStep("Resolved", status == "resolved"),

                const SizedBox(height: 30),

                buildCard(
                  title: "📍 User Location",
                  children: [
                    buildRow("Latitude", lat),
                    buildRow("Longitude", lng),
                  ],
                ),

                const SizedBox(height: 20),

                buildCard(
                  title: "🚑 Assigned Service",
                  children: [
                    buildRow("Provider", assignedProviderName.toString()),
                    buildRow("Phone", assignedProviderPhone.toString()),
                    buildRow("Vehicle", vehicleType.toString()),
                    buildRow("Distance", "$assignedDistanceKm km"),
                    buildRow("Provider ID", assignedProviderId.toString()),
                    buildRow(
                      "Collection",
                      assignedProviderCollection.toString(),
                    ),
                  ],
                ),
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

  Widget buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
