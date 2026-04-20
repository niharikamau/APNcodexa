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
    if (status == "on the way") return "On The Way";
    if (status.isEmpty) return "Pending";
    return status[0].toUpperCase() + status.substring(1);
  }

  String getServiceLabel(Map<String, dynamic> data) {
    final serviceType = data["serviceType"]?.toString().toLowerCase();

    if (serviceType == "ambulance") return "🚑 Ambulance";
    if (serviceType == "police") return "👮 Police";
    if (serviceType == "fire") return "🔥 Fire";

    final fallback = data["type"]?.toString();
    return fallback ?? "Unknown Service";
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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          "Emergency Requests",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('emergency_requests')
                .where(
                  "userId",
                  isEqualTo: currentUser.uid,
                )
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
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final doc = requests[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final status = normalizeStatus(data["status"]);
                  final statusColor = getStatusColor(status);

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        getServiceLabel(data),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "User: ${data["user"] ?? data["name"] ?? "-"}\n"
                        "Phone: ${data["phone"] ?? "-"}\n"
                        "Status: ${prettyStatus(status)}",
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: statusColor,
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/requestDetails',
                          arguments: {
                            "docId": doc.id,
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}