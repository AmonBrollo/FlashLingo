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
import 'package:flutter/foundation.dart';

void main() async {
  // CRITICAL: Ensure Flutter is initialized FIRST
  WidgetsFlutterBinding.ensureInitialized();

  // Run app in error zone to catch ALL errors
  await runZonedGuarded<Future<void>>(() async {
    try {
      // STEP 1: Initialize Firebase (MUST be first)
      debugPrint('🔧 Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized');

      // STEP 2: Initialize Crashlytics IMMEDIATELY after Firebase
      debugPrint('🔧 Initializing Crashlytics...');
      
      // Pass all uncaught Flutter errors to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      
      // Pass all uncaught async errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Enable Crashlytics collection
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      debugPrint('✅ Crashlytics initialized and enabled');
      
      // Log successful initialization
      await FirebaseCrashlytics.instance.log('App started - Crashlytics active');

      // STEP 3: Initialize ErrorHandlerService (now that Crashlytics is ready)
      await ErrorHandlerService.initialize();
      await ErrorHandlerService.logMessage('ErrorHandlerService initialized');

      // STEP 4: Initialize app services (NON-BLOCKING)
      debugPrint('🔧 Initializing app services...');
      // Don't await - let it initialize in background
      AppInitializationService.initialize().then((_) {
        debugPrint('✅ App services initialized');
      }).catchError((e, stack) {
        debugPrint('⚠️ App services initialization error: $e');
        ErrorHandlerService.logError(
          e,
          stack,
          context: 'App Services Init',
          fatal: false,
        );
      });
      
      debugPrint('✅ All critical systems initialized');
    } catch (e, stack) {
      // Log initialization error
      debugPrint('❌ CRITICAL: Initialization failed: $e');
      debugPrint('Stack: $stack');
      
      // Try to report to Crashlytics if available
      try {
        await FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: 'Critical initialization failure',
          fatal: true,
        );
      } catch (_) {
        debugPrint('⚠️ Could not report error to Crashlytics');
      }
      
      // Rethrow to show error screen
      rethrow;
    }

    // STEP 5: Run the app
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
    debugPrint('❌ UNCAUGHT ERROR: $error');
    debugPrint('Stack: $stack');
    
    // Report to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: 'Uncaught error in runZonedGuarded',
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
    
    switch (state) {
      case AppLifecycleState.resumed:
        _recordAppLifecycle('App Resumed');
        try {
          context.read<AppStateService>().onAppResumed();
        } catch (e) {
          debugPrint('⚠️ Error in onAppResumed: $e');
        }
        break;
      case AppLifecycleState.inactive:
        _recordAppLifecycle('App Inactive');
        break;
      case AppLifecycleState.paused:
        _recordAppLifecycle('App Paused');
        try {
          context.read<AppStateService>().onAppPaused();
        } catch (e) {
          debugPrint('⚠️ Error in onAppPaused: $e');
        }
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
    try {
      FirebaseCrashlytics.instance.log(event);
      debugPrint('📱 Lifecycle: $event');
    } catch (e) {
      debugPrint('⚠️ Failed to log lifecycle: $e');
    }
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
      builder: (context, child) {
        // Global error handling for widget errors
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // Log to Crashlytics
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
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