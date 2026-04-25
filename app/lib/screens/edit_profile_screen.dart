import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final bloodGroup = TextEditingController();
  final allergies = TextEditingController();
  final medicalConditions = TextEditingController();
  final medications = TextEditingController();
  final emergencyContact = TextEditingController();
  final address = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    name.text = prefs.getString("${uid}_profileName") ?? "";
    phone.text = prefs.getString("${uid}_profilePhone") ?? "";
    bloodGroup.text = prefs.getString("${uid}_bloodGroup") ?? "";
    allergies.text = prefs.getString("${uid}_allergies") ?? "";
    medicalConditions.text = prefs.getString("${uid}_medicalConditions") ?? "";
    medications.text = prefs.getString("${uid}_medications") ?? "";
    emergencyContact.text = prefs.getString("${uid}_emergencyContact") ?? "";
    address.text = prefs.getString("${uid}_address") ?? "";
  }

  Future<void> saveProfile() async {
    final nameRegex = RegExp(r'^[a-zA-Z ]+$');
    final phoneRegex = RegExp(r'^[0-9]{10}$');

    if (name.text.trim().isNotEmpty && !nameRegex.hasMatch(name.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name should contain alphabets only")),
      );
      return;
    }

    if (phone.text.trim().isNotEmpty &&
        !phoneRegex.hasMatch(phone.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone must be exactly 10 digits")),
      );
      return;
    }

    if (emergencyContact.text.trim().isNotEmpty &&
        !phoneRegex.hasMatch(emergencyContact.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency contact must be exactly 10 digits"),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    await prefs.setString("${uid}_profileName", name.text.trim());
    await prefs.setString("${uid}_profilePhone", phone.text.trim());
    await prefs.setString("${uid}_bloodGroup", bloodGroup.text.trim());
    await prefs.setString("${uid}_allergies", allergies.text.trim());
    await prefs.setString(
      "${uid}_medicalConditions",
      medicalConditions.text.trim(),
    );
    await prefs.setString("${uid}_medications", medications.text.trim());
    await prefs.setString(
      "${uid}_emergencyContact",
      emergencyContact.text.trim(),
    );
    await prefs.setString("${uid}_address", address.text.trim());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved")),
    );

    Navigator.pop(context);
  }

  Widget input(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              input("Full Name", name),
              input(
                "Phone Number",
                phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              input("Blood Group", bloodGroup),
              input("Allergies", allergies, maxLines: 2),
              input("Medical Conditions", medicalConditions, maxLines: 2),
              input("Current Medications", medications, maxLines: 2),
              input(
                "Emergency Contact",
                emergencyContact,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              input("Address / Location", address, maxLines: 2),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveProfile,
                  child: const Text("Save Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}