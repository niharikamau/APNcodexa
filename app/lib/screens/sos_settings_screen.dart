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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("SOS settings saved")));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 70,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              "SOS Settings",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            TextField(
              controller: contact1,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Emergency Contact 1",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: contact2,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Emergency Contact 2",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: SwitchListTile(
                title: const Text("Auto send Police Request"),
                subtitle: const Text(
                  "SOS will automatically create a police request",
                ),
                value: autoPolice,
                onChanged: (val) => setState(() => autoPolice = val),
              ),
            ),

            Card(
              child: SwitchListTile(
                title: const Text("Call Police"),
                subtitle: const Text("Future feature"),
                value: callPolice,
                onChanged: (val) => setState(() => callPolice = val),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveData,
                child: const Text("Save Settings"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
