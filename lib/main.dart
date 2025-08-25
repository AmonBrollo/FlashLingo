import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import '/services/review_state.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Roboto'),
    );
  }
}
