import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';
import 'services/review_state.dart';
import 'services/app_initialization_service.dart';
import 'services/app_state_service.dart';
import 'services/error_handler_service.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

void main() async {
  // Run app in error zone to catch all errors
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        ErrorHandlerService.handleFlutterError(errorDetails);
      };

      // Initialize app services
      await AppInitializationService.initialize();
      
      // Log app start
      await FirebaseCrashlytics.instance.log('App started successfully');
      
      debugPrint('✅ Firebase and Crashlytics initialized successfully');
    } catch (e, stack) {
      // Log initialization error but continue
      debugPrint('⚠️ Error during initialization: $e');
      ErrorHandlerService.logError(
        e,
        stack,
        context: 'App Initialization',
        fatal: false,
      );
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ReviewState()),
          ChangeNotifierProvider(create: (_) => AppStateService()),
        ],
        child: const FlashLango(),
      ),
    );
  }, (error, stack) {
    // Catch errors that escape the error boundary
    ErrorHandlerService.logError(
      error,
      stack,
      context: 'Uncaught Error',
      fatal: true,
    );
  });
}

class FlashLango extends StatefulWidget {
  const FlashLango({super.key});

  @override
  State<FlashLango> createState() => _FlashLangoState();
}

class _FlashLangoState extends State<FlashLango> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recordAppLifecycle('App Started');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Track app lifecycle for debugging
    switch (state) {
      case AppLifecycleState.resumed:
        _recordAppLifecycle('App Resumed');
        context.read<AppStateService>().onAppResumed();
        break;
      case AppLifecycleState.inactive:
        _recordAppLifecycle('App Inactive');
        break;
      case AppLifecycleState.paused:
        _recordAppLifecycle('App Paused');
        context.read<AppStateService>().onAppPaused();
        break;
      case AppLifecycleState.detached:
        _recordAppLifecycle('App Detached');
        break;
      case AppLifecycleState.hidden:
        _recordAppLifecycle('App Hidden');
        break;
    }
  }

  void _recordAppLifecycle(String event) {
    FirebaseCrashlytics.instance.log(event);
    debugPrint('🔄 Lifecycle: $event');
  }

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
      // Global error handling for navigation
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          ErrorHandlerService.handleFlutterError(details);
          return _buildErrorWidget(details);
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the app',
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}