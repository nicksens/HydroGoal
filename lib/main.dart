import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hydrogoal/decision_screen.dart'; // <-- This import is crucial
import 'firebase_options.dart';

void main() async {
  // Ensures that Flutter's widget binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Firebase services for your app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroGoal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // This line needs the import above to work
      home: const DecisionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
