import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String> profile = {};

  String fallback(String? value, String placeholder) {
    if (value == null || value.trim().isEmpty) return placeholder;
    return value.trim();
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    setState(() {
      profile = {
        "name": fallback(prefs.getString("${uid}_profileName"), "Add Name"),
        "phone": fallback(prefs.getString("${uid}_profilePhone"), "Add Phone"),
        "bloodGroup": fallback(
          prefs.getString("${uid}_bloodGroup"),
          "Add Blood Group",
        ),
        "allergies": fallback(
          prefs.getString("${uid}_allergies"),
          "Add Allergies",
        ),
        "medicalConditions": fallback(
          prefs.getString("${uid}_medicalConditions"),
          "Add Medical Conditions",
        ),
        "medications": fallback(
          prefs.getString("${uid}_medications"),
          "Add Medications",
        ),
        "emergencyContact": fallback(
          prefs.getString("${uid}_emergencyContact"),
          "Add Emergency Contact",
        ),
        "address": fallback(
          prefs.getString("${uid}_address"),
          "Add Address",
        ),
      };
    });
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget infoTile(String title, String value, IconData icon) {
    final isPlaceholder = value.toLowerCase().startsWith("add");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isPlaceholder ? FontWeight.w500 : FontWeight.w700,
                    color: isPlaceholder ? Colors.grey : Colors.black,
                    fontStyle:
                        isPlaceholder ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.person,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile["name"] ?? "Add Name",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? "No Email",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            sectionTitle("Account Information"),

            infoTile("Email", user?.email ?? "No Email", Icons.email_outlined),
            infoTile("Phone", profile["phone"] ?? "Add Phone", Icons.phone),
            infoTile(
              "Password",
              "Managed securely by Firebase",
              Icons.lock_outline,
            ),

            const SizedBox(height: 10),

            sectionTitle("Medical Information"),

            infoTile(
              "Blood Group",
              profile["bloodGroup"] ?? "Add Blood Group",
              Icons.bloodtype,
            ),
            infoTile(
              "Allergies",
              profile["allergies"] ?? "Add Allergies",
              Icons.warning_amber_rounded,
            ),
            infoTile(
              "Medical Conditions",
              profile["medicalConditions"] ?? "Add Medical Conditions",
              Icons.medical_information_outlined,
            ),
            infoTile(
              "Medications",
              profile["medications"] ?? "Add Medications",
              Icons.medication_outlined,
            ),
            infoTile(
              "Emergency Contact",
              profile["emergencyContact"] ?? "Add Emergency Contact",
              Icons.contact_phone_outlined,
            ),
            infoTile(
              "Address",
              profile["address"] ?? "Add Address",
              Icons.location_on_outlined,
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/editProfile');
                  loadProfile();
                },
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}