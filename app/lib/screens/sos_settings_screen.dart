import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    contact1.text = prefs.getString("contact1") ?? "";
    contact2.text = prefs.getString("contact2") ?? "";
    autoPolice = prefs.getBool("autoPolice") ?? true;
    callPolice = prefs.getBool("callPolice") ?? false;

    setState(() {});
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("contact1", contact1.text);
    await prefs.setString("contact2", contact2.text);
    await prefs.setBool("autoPolice", autoPolice);
    await prefs.setBool("callPolice", callPolice);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings Saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: contact1,
              decoration: const InputDecoration(labelText: "Contact 1"),
            ),
            TextField(
              controller: contact2,
              decoration: const InputDecoration(labelText: "Contact 2"),
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text("Auto send Police Request"),
              value: autoPolice,
              onChanged: (val) => setState(() => autoPolice = val),
            ),

            SwitchListTile(
              title: const Text("Call Police (future)"),
              value: callPolice,
              onChanged: (val) => setState(() => callPolice = val),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveData,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}