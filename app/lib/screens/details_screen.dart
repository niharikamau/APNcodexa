import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Future<String> createRequestWithCustomId(Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;
    final counterRef = firestore.collection('counters').doc('requests');

    return firestore.runTransaction((transaction) async {
      final counterSnap = await transaction.get(counterRef);

      int current = 0;
      if (counterSnap.exists) {
        current = (counterSnap.data()?["current"] ?? 0) as int;
      }

      current++;

      final id = "R${current.toString().padLeft(3, '0')}";
      final requestRef = firestore.collection('emergency_requests').doc(id);

      transaction.set(counterRef, {"current": current});
      transaction.set(requestRef, data);

      return id;
    });
  }

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false;

  final Map<String, dynamic> dummyUserLocation = {
    "name": "Sector 62, Noida",
    "lat": 23.55105395451701,
    "lng": 34.895463666438,
  };

  String getPrettyServiceLabel(String serviceType) {
    if (serviceType == "ambulance") return "🚑 Medical";
    if (serviceType == "police") return "👮 Police";
    if (serviceType == "fire") return "🔥 Fire";
    return serviceType;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final services = (args?["services"] as List?)?.cast<String>() ?? [];
    final description = args?["description"]?.toString() ?? "";
    final urgency = args?["urgency"]?.toString() ?? "low";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              services.isEmpty
                  ? "No service detected"
                  : services.map(getPrettyServiceLabel).join(" + "),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty)
              Text(
                'Description: "$description"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
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
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();

                      final nameRegex = RegExp(r'^[a-zA-Z ]+$');
                      final phoneRegex = RegExp(r'^[0-9]{10}$');

                      if (name.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all details"),
                          ),
                        );
                        return;
                      }

                      if (!nameRegex.hasMatch(name)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Name should contain alphabets only"),
                          ),
                        );
                        return;
                      }

                      if (!phoneRegex.hasMatch(phone)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Phone number must be exactly 10 digits",
                            ),
                          ),
                        );
                        return;
                      }

                      if (services.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "No valid emergency service detected",
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final incidentId =
                            "INC-${DateTime.now().millisecondsSinceEpoch}";
                        final createdDocIds = <String>[];

                        for (final serviceType in services) {
                          final requestData = {
                            "incidentId": incidentId,
                            "serviceType": serviceType,
                            "userId": FirebaseAuth.instance.currentUser!.uid,
                            "user": name,
                            "phone": phone,
                            "description": description,
                            "urgency": urgency,
                            "location": {
                              "latitude": dummyUserLocation["lat"],
                              "longitude": dummyUserLocation["lng"],
                            },
                            "status": "pending",
                            "timestamp": FieldValue.serverTimestamp(),

                            // temporary compatibility
                            "type": getPrettyServiceLabel(serviceType),
                            "name": name,
                            "userLocationName": dummyUserLocation["name"],
                          };

                          final requestId = await createRequestWithCustomId(
                            requestData,
                          );
                          createdDocIds.add(requestId);
                        }

                        if (!mounted) return;

                        Navigator.pushReplacementNamed(
                          context,
                          '/requestSent',
                          arguments: {
                            "docId": createdDocIds.isNotEmpty
                                ? createdDocIds.first
                                : null,
                            "docIds": createdDocIds,
                            "incidentId": incidentId,
                            "type": services
                                .map(getPrettyServiceLabel)
                                .join(" + "),
                            "name": name,
                            "phone": phone,
                            "userLocationName": dummyUserLocation["name"],
                          },
                        );
                      } catch (e) {
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
