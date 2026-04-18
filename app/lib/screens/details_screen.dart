import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false; // 🔥 NEW

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
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // ✅ validation FIRST
                      if (nameController.text.isEmpty ||
                          phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all details"),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        // 🔥 send to Firebase
                        await FirebaseFirestore.instance
                            .collection('emergency_requests')
                            .add({
                              "type": emergencyType,
                              "name": nameController.text,
                              "phone": phoneController.text,
                              "status": "Pending",
                              "timestamp": FieldValue.serverTimestamp(),
                            });

                        // ✅ VERY IMPORTANT
                        if (!mounted) return;

                        // 🔥 navigate properly (no going back to loading screen)
                        Navigator.pushReplacementNamed(
                          context,
                          '/requestSent',
                          arguments: {
                            "type": emergencyType,
                            "name": nameController.text,
                            "phone": phoneController.text,
                          },
                        );
                      } catch (e) {
                        // ❌ if something fails
                        setState(() => isLoading = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Something went wrong")),
                        );
                      }
                    },

              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Send Request"),
            ),
          ],
        ),
      ),
    );
  }
}
