import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
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

                  final status = data.containsKey("status")
                      ? data["status"]
                      : "Pending";

                  Color statusColor = Colors.orange;

                  if (status == "Completed") {
                    statusColor = Colors.green;
                  } else if (status == "Accepted") {
                    statusColor = Colors.blue;
                  }

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        data["type"] ?? "Unknown",
                        style: TextStyle(color: statusColor),
                      ),
                      subtitle: Text(
                        "Name: ${data["name"] ?? "-"}\n"
                        "Phone: ${data["phone"] ?? "-"}\n"
                        "Status: $status",
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/requestDetails',
                          arguments: data,
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