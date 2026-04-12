import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/error_handler_service.dart';
import '../services/app_state_service.dart';
import '../services/ui_language_provider.dart';
import 'login_screen.dart';
import 'app_router.dart';
import 'onboarding_screen.dart';

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
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        backgroundColor: Colors.brown.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
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

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                    onPressed: () => setState(() {}),
                    child: Text(loc.retry),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          ErrorHandlerService.logScreenView('AppRouter');
          // Gate onboarding for authenticated users (including anonymous).
          // FutureBuilder resolves the SharedPreferences check once per
          // auth session; the inner key ensures it rebuilds if auth changes.
          return _OnboardingGate(
            key: ValueKey(snapshot.data!.uid),
          );
        }

        ErrorHandlerService.logScreenView('LoginScreen');
        return const LoginScreen();
      },
    );
  }
}

/// Resolves whether to show onboarding or go straight to the app.
/// Keeps the check async without blocking the auth stream.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({super.key});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late Future<bool> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkFuture = shouldShowOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFuture,
      builder: (context, snapshot) {
        // While checking, show the same loading indicator used elsewhere.
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.brown,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return OnboardingScreen(
            onComplete: () {
              // Rebuild this subtree — next FutureBuilder check returns false.
              setState(() {
                _checkFuture = shouldShowOnboarding();
              });
            },
          );
        }

        return const AppRouter();
      },
    );
  }
}