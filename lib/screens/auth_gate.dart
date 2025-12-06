import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/error_handler_service.dart';
import '../services/app_state_service.dart';
import '../services/ui_language_provider.dart';
import 'login_screen.dart';
import 'app_router.dart';

/// Enhanced AuthGate with proper state management and error handling
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final appState = context.read<AppStateService>();
      if (!appState.isInitialized) {
        await appState.initialize();
      }

      await appState.logState();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'AuthGate Initialization',
        fatal: false,
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    
    // Show loading during initialization
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.brown,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                loc.initializing,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error if initialization failed
    if (_initError != null) {
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
                Text(
                  loc.initializationError,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitializing = true;
                      _initError = null;
                    });
                    _initialize();
                  },
                  child: Text(loc.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main auth stream
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Log auth state changes
        if (snapshot.hasData) {
          final user = snapshot.data!;
          ErrorHandlerService.logAuthEvent(
            'User authenticated: ${user.isAnonymous ? "Anonymous" : user.email}',
          );
          ErrorHandlerService.setUserIdentifier(
            user.isAnonymous ? 'anonymous_${user.uid}' : user.uid,
          );
        } else {
          ErrorHandlerService.logAuthEvent('User not authenticated');
          ErrorHandlerService.clearUserIdentifier();
        }

        // Handle connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.brown,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          ErrorHandlerService.logError(
            snapshot.error!,
            StackTrace.current,
            context: 'Auth Stream Error',
            fatal: false,
          );

          return Scaffold(
            backgroundColor: Colors.brown.shade50,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.authenticationError,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text(loc.retry),
                  ),
                ],
              ),
            ),
          );
        }

        // Route based on authentication state
        if (snapshot.hasData) {
          // User is logged in
          ErrorHandlerService.logScreenView('AppRouter');
          return const AppRouter();
        }

        // User is not logged in
        ErrorHandlerService.logScreenView('LoginScreen');
        return const LoginScreen();
      },
    );
  }
}