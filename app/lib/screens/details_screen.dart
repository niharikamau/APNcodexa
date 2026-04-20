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
                        final docRef = await FirebaseFirestore.instance
                            .collection('emergency_requests')
                            .add({
                          // backend format your friend wants
                          "serviceType": getServiceType(emergencyType),
                          "userId": FirebaseAuth.instance.currentUser!.uid,
                          "location": {
                            "latitude": dummyUserLocation["lat"],
                            "longitude": dummyUserLocation["lng"],
                          },
                          "status": "pending",

                          // keep these temporarily so your current Flutter UI does not break
                          "type": emergencyType,
                          "name": nameController.text,
                          "phone": phoneController.text,
                          "userLocationName": dummyUserLocation["name"],
                        });

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
                        setState(() => isLoading = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Something went wrong: $e")),
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