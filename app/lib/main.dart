import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/location_screen.dart';
import 'screens/details_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // starting screen
      initialRoute: '/',

      // all routes (navigation)
      routes: {
        '/': (context) => const HomeScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/location': (context) => const LocationScreen(),
        '/details': (context) => const DetailsScreen(),
      },
    );
  }
}