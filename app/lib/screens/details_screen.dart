import 'package:flutter/material.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final emergencyType =
        ModalRoute.of(context)?.settings.arguments as String? ?? "Unknown";

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              emergencyType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Your Name"),
            ),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/location',
                  arguments: {
                    "type": emergencyType,
                    "name": nameController.text,
                    "phone": phoneController.text,
                  },
                );
              },
              child: const Text("Send Request"),
            ),
          ],
        ),
      ),
    );
  }
}
