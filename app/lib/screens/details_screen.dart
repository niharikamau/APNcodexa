import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false;

  // Dummy location for now
  final Map<String, dynamic> dummyUserLocation = {
    "name": "Sector 62, Noida",
    "lat": 28.6280,
    "lng": 77.3649,
  };

  String getServiceType(String emergencyType) {
    if (emergencyType.contains("Medical")) return "ambulance";
    if (emergencyType.contains("Police")) return "police";
    if (emergencyType.contains("Fire")) return "fire";
    return "unknown";
  }

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
                        print("🔥 Sending request to Firebase...");

                        final docRef = await FirebaseFirestore.instance
                            .collection('emergency_requests')
                            .add({
                              "serviceType": emergencyType.contains("Medical")
                                  ? "ambulance"
                                  : emergencyType.contains("Police")
                                  ? "police"
                                  : "fire",

                              "userId": FirebaseAuth.instance.currentUser!.uid,
                              "user": nameController.text,
                              "phone": phoneController.text,

                              "location": {
                                "latitude": 28.6280,
                                "longitude": 77.3649,
                              },

                              "status": "pending",
                              "timestamp": FieldValue.serverTimestamp(),

                              // temporary compatibility fields for current Flutter screens
                              "type": emergencyType,
                              "name": nameController.text,
                              "userLocationName": "Sector 62, Noida",
                            });

                        print(
                          "✅ Request sent successfully. Doc ID: ${docRef.id}",
                        );

                        if (!mounted) return;

                        Navigator.pushReplacementNamed(
                          context,
                          '/requestSent',
                          arguments: {
                            "docId": docRef.id,
                            "type": emergencyType,
                            "name": nameController.text,
                            "phone": phoneController.text,
                            "userLocationName": dummyUserLocation["name"],
                            "assignedServiceName": "To be assigned",
                          },
                        );
                      } catch (e) {
                        print("❌ Firebase write failed: $e");

                        if (mounted) {
                          setState(() => isLoading = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Something went wrong: $e")),
                          );
                        }
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
