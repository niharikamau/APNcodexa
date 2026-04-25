import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  bool isSendingSOS = false;

  Future<void> triggerSOS() async {
    if (isSendingSOS) return;

    setState(() => isSendingSOS = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final autoPolice = prefs.getBool("${uid}_autoPolice") ?? true;

      if (!autoPolice) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auto police request is disabled in SOS settings"),
          ),
        );
        setState(() => isSendingSOS = false);
        return;
      }

      final incidentId = "SOS-${DateTime.now().millisecondsSinceEpoch}";

      final requestData = {
        "incidentId": incidentId,
        "isSOS": true,
        "serviceType": "police",
        "userId": uid,
        "user": "SOS User",
        "phone": "N/A",
        "urgency": "critical",
        "location": {
          "latitude": 23.55105395451701,
          "longitude": 34.895463666438,
        },
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
        "type": "Police SOS",
        "name": "SOS User",
        "userLocationName": "Sector 62, Noida",
      };

      final requestId = await createRequestWithCustomId(requestData);

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/requestSent',
        arguments: {
          "docId": requestId,
          "docIds": [requestId],
          "incidentId": incidentId,
          "type": "Police SOS",
          "name": "SOS User",
          "phone": "N/A",
          "userLocationName": "Sector 62, Noida",
          "urgency": "critical",
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("SOS failed: $e")));
    } finally {
      if (mounted) setState(() => isSendingSOS = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            const SizedBox(height: 10),

            const Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: Colors.red,
            ),

            const SizedBox(height: 18),

            const Text(
              "Emergency Response",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Send emergency alerts, notify responders, and track help in real time.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 34),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.red),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current Location",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Sector 62, Noida",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 38),

            SizedBox(
              width: double.infinity,
              height: 78,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: isSendingSOS ? null : triggerSOS,
                child: isSendingSOS
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Send SOS Alert",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.4),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/emergency');
                },
                child: const Text(
                  "Report Emergency",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 34),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "Use SOS for immediate police alert. Use Report Emergency to describe the situation and notify multiple services.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
