import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/location_screen.dart';
import 'screens/details_screen.dart';
import 'screens/status_screen.dart';
import 'screens/request_sent_screen.dart';
import 'screens/request_details_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

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

      // 🔥 AUTH BASED ENTRY (THIS IS THE KEY CHANGE)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // logged in
          if (snapshot.hasData) {
            return const MainScreen();
          }

          // not logged in
          return const LoginScreen();
        },
      ),

      // routes (keep these)
      routes: {
        '/emergency': (context) => const EmergencyScreen(),
        '/location': (context) => const LocationScreen(),
        '/details': (context) => const DetailsScreen(),
        '/status': (context) => const StatusScreen(),
        '/requestSent': (context) => const RequestSentScreen(),
        '/requestDetails': (context) => const RequestDetailsScreen(),
        '/tracking': (context) => const TrackingScreen(),
      },
    );
  }
}