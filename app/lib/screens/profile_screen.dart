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
        "name": prefs.getString("${uid}_profileName") ?? "Add Name",
        "phone": prefs.getString("${uid}_profilePhone") ?? "Add Phone",
        "bloodGroup": prefs.getString("${uid}_bloodGroup") ?? "Add Blood Group",
        "allergies": prefs.getString("${uid}_allergies") ?? "Add Allergies",
        "medicalConditions":
            prefs.getString("${uid}_medicalConditions") ?? "Add Conditions",
        "medications": prefs.getString("${uid}_medications") ?? "Add Medications",
        "emergencyContact":
            prefs.getString("${uid}_emergencyContact") ?? "Add Emergency Contact",
        "address": prefs.getString("${uid}_address") ?? "Add Address",
      };
    });
  }

  Widget infoTile(String title, String value, IconData icon) {
    final isPlaceholder = value.toLowerCase().startsWith("add");

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          value,
          style: TextStyle(
            color: isPlaceholder ? Colors.grey : Colors.black,
            fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 55)),
            const SizedBox(height: 15),
            Text(
              profile["name"] ?? "Add Name",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(user?.email ?? "No Email"),
            const SizedBox(height: 25),

            infoTile("Email", user?.email ?? "No Email", Icons.email),
            infoTile("Phone", profile["phone"] ?? "Add Phone", Icons.phone),
            infoTile("Password", "Managed securely by Firebase", Icons.lock),

            const SizedBox(height: 12),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Medical Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            infoTile("Blood Group", profile["bloodGroup"] ?? "Add Blood Group",
                Icons.bloodtype),
            infoTile("Allergies", profile["allergies"] ?? "Add Allergies",
                Icons.warning),
            infoTile(
              "Medical Conditions",
              profile["medicalConditions"] ?? "Add Conditions",
              Icons.medical_information,
            ),
            infoTile("Medications", profile["medications"] ?? "Add Medications",
                Icons.medication),
            infoTile(
              "Emergency Contact",
              profile["emergencyContact"] ?? "Add Emergency Contact",
              Icons.contact_phone,
            ),
            infoTile("Address", profile["address"] ?? "Add Address",
                Icons.location_on),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/editProfile');
                  loadProfile();
                },
                child: const Text("Edit Profile"),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}