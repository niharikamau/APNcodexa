import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool isSending = false;

  Future<void> triggerSOS() async {
    if (isSending) return;

    setState(() => isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final autoPolice = prefs.getBool("autoPolice") ?? true;

      if (!autoPolice) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auto police request is disabled"),
          ),
        );
        return;
      }

      final incidentId = "SOS-${DateTime.now().millisecondsSinceEpoch}";

      await FirebaseFirestore.instance
          .collection('emergency_requests')
          .add({
        "incidentId": incidentId,
        "isSOS": true,

        "serviceType": "police",
        "type": "Police SOS",

        "userId": FirebaseAuth.instance.currentUser!.uid,
        "user": "SOS User",
        "phone": "N/A",

        "urgency": "critical",

        "location": {
          "latitude": 28.622934,
          "longitude": 77.364026,
        },

        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),

        "userLocationName": "Emergency Location",
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SOS request sent")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Emergency SOS",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Press the button below to immediately alert emergency services.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 90,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isSending ? null : triggerSOS,
                child: isSending
                    ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SEND SOS",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "This will immediately notify police and share your location.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}