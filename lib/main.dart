import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/review_state.dart';
import 'services/app_initialization_service.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize app services
    await AppInitializationService.initialize();
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue with app startup even if Firebase fails
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ReviewState(),
      child: const FlashLango(),
    ),
  );
}

class FlashLango extends StatelessWidget {
  const FlashLango({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashLango',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
