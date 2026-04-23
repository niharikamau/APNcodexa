import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String? selectedService;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Mic failed: $e")),
    );
  }
}

  void handleSubmit() {
    final description = descriptionController.text.trim();

    Set<String> finalServices = {};

    if (selectedService != null) {
      finalServices.add(selectedService!);
    }

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

  Widget buildServiceButton(String label, String value) {
    final isSelected = selectedService == value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(18),
            backgroundColor: isSelected ? Colors.blue : null,
          ),
          onPressed: () {
            setState(() {
              selectedService = selectedService == value ? null : value;
            });
          },
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Select Emergency Type (Optional)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            buildServiceButton("🚑 Medical", "ambulance"),
            buildServiceButton("🔥 Fire", "fire"),
            buildServiceButton("👮 Police", "police"),

            const SizedBox(height: 25),

            // 🔥 DESCRIPTION + MIC
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Describe emergency or use mic...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleListening,
                ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Send Emergency Request",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}