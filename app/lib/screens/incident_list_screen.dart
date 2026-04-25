import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';

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
    if (type == "ambulance") return "Ambulance";
    if (type == "police") return "Police";
    if (type == "fire") return "Fire";
    return serviceType;
  }

  bool isSosRequest(Map<String, dynamic> data) {
    return data["isSOS"] == true ||
        (data["type"]?.toString().contains("SOS") ?? false);
  }
  Widget _pill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

Color _urgencyColor(String urgency) {
  final u = urgency.toLowerCase();
  if (u == "critical") return Colors.red;
  if (u == "high") return Colors.orange;
  if (u == "medium") return Colors.blue;
  return Colors.grey;
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
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

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: sosGroup
                        ? Colors.red.withOpacity(0.5)
                        : Colors.grey.shade300,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              sosGroup
                                  ? Icons.warning_amber_rounded
                                  : Icons.folder_outlined,
                              color: sosGroup ? Colors.red : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              sosGroup ? "SOS Incident" : incidentId,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const Icon(Icons.chevron_right),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(
                            prettyStatus(overallStatus),
                            getStatusColor(overallStatus),
                          ),
                          _pill(urgency.toUpperCase(), _urgencyColor(urgency)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        "Services: ${services.join(", ")}",
                        style: const TextStyle(color: Colors.black87),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Location: $locationName",
                        style: const TextStyle(color: Colors.black54),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Requests: ${requests.length}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
