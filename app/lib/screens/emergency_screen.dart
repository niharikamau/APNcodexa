import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'main_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Set<String> selectedServices = {};
  final TextEditingController descriptionController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // 🔥 SERVICE CLASSIFIER
  Set<String> classifyServices(String text) {
    final msg = text.toLowerCase();
    final services = <String>{};

    if (msg.contains("fire") || msg.contains("smoke") || msg.contains("burn")) {
      services.add("fire");
    }

    if (msg.contains("robbery") ||
        msg.contains("thief") ||
        msg.contains("attack") ||
        msg.contains("gun")) {
      services.add("police");
    }

    if (msg.contains("blood") ||
        msg.contains("bleeding") ||
        msg.contains("injury") ||
        msg.contains("unconscious") ||
        msg.contains("heart attack") ||
        msg.contains("not breathing")) {
      services.add("ambulance");
    }

    return services;
  }

  // 🔥 URGENCY CLASSIFIER
  String classifyUrgency(String text) {
    final msg = text.toLowerCase();

    if (msg.contains("not breathing") ||
        msg.contains("heart attack") ||
        msg.contains("critical") ||
        msg.contains("gunshot") ||
        msg.contains("fire spreading")) {
      return "critical";
    }

    if (msg.contains("blood") ||
        msg.contains("bleeding") ||
        msg.contains("robbery") ||
        msg.contains("attack") ||
        msg.contains("gun") ||
        msg.contains("accident") ||
        msg.contains("unconscious") ||
        msg.contains("severe")) {
      return "high";
    }

    if (msg.contains("pain") ||
        msg.contains("help") ||
        msg.contains("injury") ||
        msg.contains("smoke")) {
      return "medium";
    }

    return "low";
  }

  // 🎤 SPEECH FUNCTION
  void _toggleListening() async {
    try {
      if (!_isListening) {
        bool available = await _speech.initialize(
          onStatus: (status) {
            print("Speech status: $status");
          },
          onError: (errorNotification) {
            print("Speech error: $errorNotification");
          },
        );

        print("Speech available: $available");

        if (!available) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Speech recognition not available on this device"),
            ),
          );
          return;
        }

        setState(() => _isListening = true);

        await _speech.listen(
          onResult: (result) {
            setState(() {
              descriptionController.text = result.recognizedWords;
            });
          },
        );
      } else {
        setState(() => _isListening = false);
        await _speech.stop();
      }
    } catch (e) {
      print("Mic error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Mic failed: $e")));
    }
  }

  void handleSubmit() {
    final description = descriptionController.text.trim();

    Set<String> finalServices = {};
    finalServices.addAll(selectedServices);

    finalServices.addAll(classifyServices(description));

    if (finalServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select a service or enter a description"),
        ),
      );
      return;
    }

    final urgency = classifyUrgency(description);

    Navigator.pushNamed(
      context,
      '/details',
      arguments: {
        "services": finalServices.toList(),
        "description": description,
        "urgency": urgency,
      },
    );
  }

  Widget buildServiceButton(String label, String value, IconData icon) {
  final isSelected = selectedServices.contains(value);

  return GestureDetector(
    onTap: () {
      setState(() {
        if (isSelected) {
          selectedServices.remove(value);
        } else {
          selectedServices.add(value);
        }
      });
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? Colors.red : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? Colors.red : Colors.black54),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Report Emergency"),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Services",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Choose services or describe the situation below.",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            buildServiceButton("Medical", "ambulance", Icons.local_hospital),
            buildServiceButton("Fire", "fire", Icons.local_fire_department),
            buildServiceButton("Police", "police", Icons.local_police),

            const SizedBox(height: 28),

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Describe the emergency...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                    onPressed: _toggleListening,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Submit Request",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
