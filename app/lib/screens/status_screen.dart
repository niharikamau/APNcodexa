import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

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

  IconData getServiceIcon(Map<String, dynamic> data) {
    final serviceType = data["serviceType"]?.toString().toLowerCase();

    if (serviceType == "ambulance") return Icons.local_hospital;
    if (serviceType == "police") return Icons.local_police;
    if (serviceType == "fire") return Icons.local_fire_department;

    return Icons.warning_amber_rounded;
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

  Widget pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            .where("userId", isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
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
            return const Center(child: Text("No requests yet"));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Emergency Requests",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${requests.length} active and past request${requests.length == 1 ? "" : "s"}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }

              final doc = requests[index - 1];
              final data = doc.data() as Map<String, dynamic>;

              final status = normalizeStatus(data["status"]);
              final statusColor = getStatusColor(status);

              final urgency =
                  (data["urgency"] ?? "low").toString().toLowerCase();
              final urgencyColor = getUrgencyColor(urgency);

              final serviceName = getServiceLabel(data);
              final serviceIcon = getServiceIcon(data);

              final user = (data["user"] ?? data["name"] ?? "-").toString();
              final phone = (data["phone"] ?? "-").toString();
              final isSOS = data["isSOS"] == true ||
                  (data["type"]?.toString().contains("SOS") ?? false);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSOS
                        ? Colors.red.withOpacity(0.45)
                        : Colors.grey.shade300,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/requestDetails',
                      arguments: {"docId": doc.id},
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
                            child: Icon(serviceIcon, color: statusColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isSOS ? "SOS Request" : serviceName,
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
                          pill(prettyStatus(status), statusColor),
                          pill(urgency.toUpperCase(), urgencyColor),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        "User: $user",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Phone: $phone",
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