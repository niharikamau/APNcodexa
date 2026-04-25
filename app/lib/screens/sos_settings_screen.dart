import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SOSSettingsScreen extends StatefulWidget {
  const SOSSettingsScreen({super.key});

  @override
  State<SOSSettingsScreen> createState() => _SOSSettingsScreenState();
}

class _SOSSettingsScreenState extends State<SOSSettingsScreen> {
  final contact1 = TextEditingController();
  final contact2 = TextEditingController();

  bool autoPolice = true;
  bool callPolice = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    contact1.text = prefs.getString("${uid}_contact1") ?? "";
    contact2.text = prefs.getString("${uid}_contact2") ?? "";
    autoPolice = prefs.getBool("${uid}_autoPolice") ?? true;
    callPolice = prefs.getBool("${uid}_callPolice") ?? false;

    setState(() {});
  }

  Future<void> saveData() async {
    final phoneRegex = RegExp(r'^[0-9]{10}$');

    if (contact1.text.trim().isNotEmpty &&
        !phoneRegex.hasMatch(contact1.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact 1 must be exactly 10 digits")),
      );
      return;
    }

    if (contact2.text.trim().isNotEmpty &&
        !phoneRegex.hasMatch(contact2.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact 2 must be exactly 10 digits")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await prefs.setString("${uid}_contact1", contact1.text.trim());
    await prefs.setString("${uid}_contact2", contact2.text.trim());
    await prefs.setBool("${uid}_autoPolice", autoPolice);
    await prefs.setBool("${uid}_callPolice", callPolice);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS settings saved")),
    );
  }

  Widget inputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget settingCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        value: value,
        activeColor: Colors.red,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SOS Settings",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Configure emergency contacts and SOS behavior.",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 26),

            const Text(
              "Emergency Contacts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            inputField("Emergency Contact 1", contact1),
            const SizedBox(height: 6),
            inputField("Emergency Contact 2", contact2),

            const SizedBox(height: 20),

            const Text(
              "SOS Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            settingCard(
              title: "Auto-send police request",
              subtitle: "Creates a police emergency request when SOS is triggered.",
              value: autoPolice,
              onChanged: (val) => setState(() => autoPolice = val),
            ),

            settingCard(
              title: "Call police",
              subtitle: "Reserved for future direct-calling support.",
              value: callPolice,
              onChanged: (val) => setState(() => callPolice = val),
            ),

            const SizedBox(height: 24),

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
                onPressed: saveData,
                child: const Text(
                  "Save Settings",
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