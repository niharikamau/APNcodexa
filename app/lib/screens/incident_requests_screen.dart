import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';

class IncidentRequestsScreen extends StatelessWidget {
  const IncidentRequestsScreen({super.key});

  String normalizeStatus(dynamic rawStatus) {
    if (rawStatus == null) return "pending";
    return rawStatus.toString().trim().toLowerCase();
  }

  String prettyStatus(String status) {
    if (status == "on_the_way") return "On The Way";
    if (status.isEmpty) return "Pending";
    return status[0].toUpperCase() + status.substring(1);
  }

  String getServiceLabel(Map<String, dynamic> data) {
    final serviceType = data["serviceType"]?.toString().toLowerCase();
    if (serviceType == "ambulance") return "Ambulance";
    if (serviceType == "police") return "Police";
    if (serviceType == "fire") return "Fire";
    return data["type"]?.toString() ?? "Unknown Service";
  }

  Color getStatusColor(String status) {
    if (status == "pending") return Colors.orange;
    if (status == "assigned") return Colors.blue;
    if (status == "on_the_way") return Colors.purple;
    if (status == "resolved") return Colors.green;
    return Colors.grey;
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

  IconData _getServiceIcon(Map<String, dynamic> data) {
    final type = data["serviceType"]?.toString().toLowerCase();

    if (type == "ambulance") return Icons.local_hospital;
    if (type == "police") return Icons.local_police;
    if (type == "fire") return Icons.local_fire_department;

    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final incidentId = args["incidentId"]?.toString() ?? "";
    final isSosGroup = args["isSosGroup"] == true;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isSosGroup ? "SOS Requests" : "Incident Requests"),
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
        title: Text(isSosGroup ? "SOS Requests" : "Incident Requests"),
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

          if (!snapshot.hasData) {
            return const Center(child: Text("No requests found"));
          }

          final allDocs = snapshot.data!.docs;

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (isSosGroup) {
              return isSosRequest(data) &&
                  ((data["incidentId"] == null) ||
                      (data["incidentId"]?.toString().startsWith("SOS-") ??
                          false));
            }

            return (data["incidentId"]?.toString() ?? "") == incidentId;
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
              child: Text("No requests found for this incident"),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    isSosGroup ? "SOS Incidents" : "Incident ID: $incidentId",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = normalizeStatus(data["status"]);
                      final statusColor = getStatusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/tracking',
                              arguments: {"docId": doc.id},
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getServiceIcon(data),
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      getServiceLabel(
                                        data,
                                      ).replaceAll(RegExp(r'[^\w\s+]'), ''),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const Icon(Icons.chevron_right),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 8,
                                children: [
                                  _pill(prettyStatus(status), statusColor),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "User: ${(data["user"] ?? data["name"] ?? "-").toString()}",
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
