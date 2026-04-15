import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select Emergency Type",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            buildEmergencyButton(context, "🚑 Medical"),
            buildEmergencyButton(context, "🔥 Fire"),
            buildEmergencyButton(context, "👮 Police"),
          ],
        ),
      ),
    );
  }
}

Widget buildEmergencyButton(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(18)),
        onPressed: () {
          print("CLICKED: $title"); // 👈 ADD THIS
          Navigator.pushNamed(context, '/details', arguments: title,);
        },
        child: Text(title, style: const TextStyle(fontSize: 18)),
      ),
    ),
  );
}
