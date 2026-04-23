import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncidentListScreen extends StatelessWidget {
  const IncidentListScreen({super.key});

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

  String getServiceLabel(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type == "ambulance") return "🚑 Ambulance";
    if (type == "police") return "👮 Police";
    if (type == "fire") return "🔥 Fire";
    return serviceType;
  }

  bool isSosRequest(Map<String, dynamic> data) {
    return data["isSOS"] == true ||
        (data["type"]?.toString().contains("SOS") ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Incidents"),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: const Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incidents"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            .where("userId", isEqualTo: currentUser.uid)
            .orderBy("timestamp", descending: true)
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No incidents yet"));
          }

          final docs = snapshot.data!.docs;
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            String incidentId = (data["incidentId"] ?? "").toString().trim();

            if (incidentId.isEmpty && isSosRequest(data)) {
              incidentId = "SOS_INCIDENTS";
            } else if (incidentId.isEmpty) {
              incidentId = "NO_INCIDENT_ID";
            }

            grouped.putIfAbsent(incidentId, () => []);
            grouped[incidentId]!.add(doc);
          }

          final incidentEntries = grouped.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidentEntries.length,
            itemBuilder: (context, index) {
              final entry = incidentEntries[index];
              final incidentId = entry.key;
              final requests = entry.value;

              final firstData = requests.first.data() as Map<String, dynamic>;
              final bool sosGroup =
                  incidentId == "SOS_INCIDENTS" || isSosRequest(firstData);

              final statuses = requests
                  .map(
                    (doc) => normalizeStatus(
                      (doc.data() as Map<String, dynamic>)["status"],
                    ),
                  )
                  .toList();

              String overallStatus = "pending";
              if (statuses.any((s) => s == "on_the_way")) {
                overallStatus = "on_the_way";
              } else if (statuses.any((s) => s == "assigned")) {
                overallStatus = "assigned";
              } else if (statuses.every((s) => s == "resolved")) {
                overallStatus = "resolved";
              }

              final services = requests
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return getServiceLabel(
                      (data["serviceType"] ?? "unknown").toString(),
                    );
                  })
                  .toSet()
                  .toList();

              final urgency = (firstData["urgency"] ?? "low").toString();
              final locationName =
                  (firstData["userLocationName"] ?? "Unknown location")
                      .toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text(
                    sosGroup ? "SOS Incident" : incidentId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Services: ${services.join(", ")}"),
                        Text("Urgency: ${urgency.toUpperCase()}"),
                        Text("Location: $locationName"),
                        Text(
                          "Overall Status: ${prettyStatus(overallStatus)}",
                          style: TextStyle(
                            color: getStatusColor(overallStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text("Requests: ${requests.length}"),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/incidentRequests',
                      arguments: {
                        "incidentId": incidentId,
                        "isSosGroup": incidentId == "SOS_INCIDENTS",
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
