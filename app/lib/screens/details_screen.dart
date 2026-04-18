import 'dart:math';
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

  // 🔥 Dummy user location
  final Map<String, dynamic> dummyUserLocation = {
    "name": "Sector 62, Noida",
    "lat": 28.6280,
    "lng": 77.3649,
  };

  // 🔥 Dummy service data for MVP
  final List<Map<String, dynamic>> ambulances = [
    {
      "name": "Ambulance A101",
      "phone": "9876543210",
      "lat": 28.6265,
      "lng": 77.3660,
      "type": "Medical"
    },
    {
      "name": "Ambulance A102",
      "phone": "9876543211",
      "lat": 28.6400,
      "lng": 77.3800,
      "type": "Medical"
    },
  ];

  final List<Map<String, dynamic>> policeUnits = [
    {
      "name": "Police Unit P201",
      "phone": "9876500011",
      "lat": 28.6295,
      "lng": 77.3620,
      "type": "Police"
    },
    {
      "name": "Police Unit P202",
      "phone": "9876500012",
      "lat": 28.6500,
      "lng": 77.3900,
      "type": "Police"
    },
  ];

  final List<Map<String, dynamic>> fireUnits = [
    {
      "name": "Fire Unit F301",
      "phone": "9876600011",
      "lat": 28.6272,
      "lng": 77.3618,
      "type": "Fire"
    },
    {
      "name": "Fire Unit F302",
      "phone": "9876600012",
      "lat": 28.6450,
      "lng": 77.3880,
      "type": "Fire"
    },
  ];

  double distance(double lat1, double lng1, double lat2, double lng2) {
    return sqrt(pow(lat1 - lat2, 2) + pow(lng1 - lng2, 2));
  }

  Map<String, dynamic> findNearestService(String emergencyType) {
    List<Map<String, dynamic>> services = [];

    if (emergencyType.contains("Medical")) {
      services = ambulances;
    } else if (emergencyType.contains("Police")) {
      services = policeUnits;
    } else if (emergencyType.contains("Fire")) {
      services = fireUnits;
    }

    Map<String, dynamic> nearest = services.first;
    double minDistance = distance(
      dummyUserLocation["lat"],
      dummyUserLocation["lng"],
      nearest["lat"],
      nearest["lng"],
    );

    for (final service in services) {
      final d = distance(
        dummyUserLocation["lat"],
        dummyUserLocation["lng"],
        service["lat"],
        service["lng"],
      );

      if (d < minDistance) {
        minDistance = d;
        nearest = service;
      }
    }

    return nearest;
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
                        final assignedService =
                            findNearestService(emergencyType);

                        final docRef = await FirebaseFirestore.instance
                            .collection('emergency_requests')
                            .add({
                          "type": emergencyType,
                          "name": nameController.text,
                          "phone": phoneController.text,
                          "status": "Pending",
                          "timestamp": FieldValue.serverTimestamp(),
                          "userId": FirebaseAuth.instance.currentUser!.uid,

                          // user location
                          "userLocationName": dummyUserLocation["name"],
                          "userLat": dummyUserLocation["lat"],
                          "userLng": dummyUserLocation["lng"],

                          // assigned nearest service
                          "assignedServiceName": assignedService["name"],
                          "assignedServicePhone": assignedService["phone"],
                          "assignedServiceLat": assignedService["lat"],
                          "assignedServiceLng": assignedService["lng"],
                          "assignedServiceType": assignedService["type"],
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
                            "assignedServiceName": assignedService["name"],
                          },
                        );
                      } catch (e) {
                        setState(() => isLoading = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Something went wrong"),
                          ),
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