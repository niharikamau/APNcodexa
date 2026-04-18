import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final status = data["status"] ?? "Pending";

    return Scaffold(
      appBar: AppBar(title: const Text("Request Tracking")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildStep(
              "Request Sent",
              true,
            ),
            buildStep(
              "Help Assigned",
              status == "Accepted" || status == "Completed",
            ),
            buildStep(
              "Incident Resolved",
              status == "Completed",
            ),
          ],
        ),
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