import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firebase_user_preferences.dart';
import '../services/repetition_service.dart';
import '../services/deck_loader.dart';
import '../services/loading_with_timeout.dart';
import '../services/error_handler_service.dart';
import '../services/app_state_service.dart';
import '../models/flashcard_deck.dart';
import 'login_screen.dart';
import 'base_language_selector_screen.dart';
import 'target_language_selector_screen.dart';
import 'flashcard_screen.dart';
import 'deck_selector_screen.dart';

/// Enhanced AppRouter with navigation guards and state restoration
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  String _loadingStatus = 'Initializing...';
  bool _hasError = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  Future<void> _loadApp() async {
    if (_isNavigating) return; // Prevent multiple navigations

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _loadingStatus = 'Initializing...';
    });

    await ErrorHandlerService.logMessage('AppRouter: Starting app load');

    try {
      final screen = await _determineStartScreen();
      
      if (!mounted) return;
      
      setState(() => _isNavigating = true);
      
      // Use pushReplacement to avoid back navigation issues
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
      
      await ErrorHandlerService.logMessage('AppRouter: Navigation completed');
    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'AppRouter Load',
        fatal: false,
      );

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getReadableError(e);
          _isNavigating = false;
        });
      }
    }
  }

  String _getReadableError(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('timeout')) {
      return 'Connection timeout. Please check your internet.';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (errorStr.contains('permission')) {
      return 'Permission denied. Please check your settings.';
    }
    return 'An unexpected error occurred.';
  }

  Future<Widget> _determineStartScreen() async {
    try {
      // Step 1: Check authentication with timeout
      setState(() => _loadingStatus = 'Checking authentication...');
      await ErrorHandlerService.logMessage('Step 1: Checking auth');
      
      final user = await LoadingWithTimeout.execute(
        operation: () async => FirebaseAuth.instance.currentUser,
        timeout: const Duration(seconds: 5),
        operationName: 'Authentication check',
      );

      if (user == null) {
        await ErrorHandlerService.logMessage('No user found, going to login');
        return const LoginScreen();
      }

      await ErrorHandlerService.logMessage(
        'User authenticated: ${user.isAnonymous ? "Anonymous" : user.email}',
      );

      // Step 2: Check if app needs data refresh
      final appState = context.read<AppStateService>();
      if (appState.shouldRefreshData()) {
        setState(() => _loadingStatus = 'Refreshing data...');
        await ErrorHandlerService.logMessage('Refreshing stale data');
        await appState.refreshData();
      }

      // Step 3: Load preferences with timeout
      setState(() => _loadingStatus = 'Loading preferences...');
      await ErrorHandlerService.logMessage('Step 2: Loading preferences');
      
      final prefs = await LoadingWithTimeout.execute(
        operation: () => FirebaseUserPreferences.loadPreferences(),
        timeout: const Duration(seconds: 8),
        operationName: 'Load preferences',
      );

      final baseLang = prefs['baseLanguage'];
      final targetLang = prefs['targetLanguage'];
      final deckKey = prefs['deckKey'];

      // Log preferences state
      await ErrorHandlerService.logMessage(
        'Preferences: base=$baseLang, target=$targetLang, deck=$deckKey',
      );

      // Navigate based on setup completion
      if (baseLang == null) {
        await ErrorHandlerService.logMessage('No base language, going to setup');
        return const BaseLanguageSelectorScreen();
      }
      
      if (targetLang == null) {
        await ErrorHandlerService.logMessage('No target language, going to setup');
        return TargetLanguageSelectorScreen(baseLanguage: baseLang);
      }

      // Step 4: Load decks with timeout
      setState(() => _loadingStatus = 'Loading flashcard decks...');
      await ErrorHandlerService.logMessage('Step 3: Loading decks');
      
      final decks = await LoadingWithTimeout.execute(
        operation: () => DeckLoader.loadDecks(),
        timeout: const Duration(seconds: 8),
        operationName: 'Load decks',
      );

      if (decks.isEmpty) {
        await ErrorHandlerService.logError(
          Exception('No decks found'),
          StackTrace.current,
          context: 'Deck Loading',
          fatal: false,
        );
        
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'No flashcard decks found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Please check your installation'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _handleRetry(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await ErrorHandlerService.logMessage('Loaded ${decks.length} decks');

      // Step 5: Decide between deck selector or specific deck
      // If user has a saved deck preference, check if they want to continue or see all decks
      if (deckKey != null && deckKey != 'forgotten') {
        // Check if user was in middle of studying
        final appState = context.read<AppStateService>();
        final timeSinceActive = appState.getTimeSinceLastActive();
        
        // If recently active (< 10 minutes), go to deck selector to show all options
        if (timeSinceActive != null && timeSinceActive.inMinutes < 10) {
          await ErrorHandlerService.logMessage('Recent activity, going to deck selector');
          return DeckSelectorScreen(
            baseLanguage: baseLang,
            targetLanguage: targetLang,
            decks: decks,
          );
        }
      }

      // Default: Go to deck selector to let user choose
      await ErrorHandlerService.logMessage('Going to deck selector');
      return DeckSelectorScreen(
        baseLanguage: baseLang,
        targetLanguage: targetLang,
        decks: decks,
      );

    } catch (e, stack) {
      await ErrorHandlerService.logError(
        e,
        stack,
        context: 'Determine Start Screen',
        fatal: false,
      );

      // If this is a timeout or network error, try local-only recovery
      if (e.toString().contains('timeout') || e.toString().contains('network')) {
        try {
          setState(() => _loadingStatus = 'Using offline data...');
          await ErrorHandlerService.logMessage('Attempting offline recovery');
          return await _loadWithLocalDataOnly();
        } catch (localError, localStack) {
          await ErrorHandlerService.logError(
            localError,
            localStack,
            context: 'Local Recovery Failed',
            fatal: false,
          );
        }
      }

      // Complete fallback to setup
      await ErrorHandlerService.logMessage('Falling back to base language setup');
      return const BaseLanguageSelectorScreen();
    }
  }

  /// Attempt to load using only local data (no Firebase calls)
  Future<Widget> _loadWithLocalDataOnly() async {
    await ErrorHandlerService.logMessage('Loading with local data only');
    
    final prefs = await FirebaseUserPreferences.loadPreferencesLocal();
    final baseLang = prefs['baseLanguage'];
    final targetLang = prefs['targetLanguage'];

    if (baseLang == null || targetLang == null) {
      await ErrorHandlerService.logMessage('No local preferences, going to setup');
      return const BaseLanguageSelectorScreen();
    }

    final decks = await DeckLoader.loadDecks();
    if (decks.isEmpty) {
      await ErrorHandlerService.logMessage('No local decks found');
      return const BaseLanguageSelectorScreen();
    }

    await ErrorHandlerService.logMessage('Successfully loaded local data');
    
    return DeckSelectorScreen(
      baseLanguage: baseLang,
      targetLanguage: targetLang,
      decks: decks,
    );
  }

  void _handleRetry() {
    if (_retryCount < _maxRetries) {
      setState(() {
        _retryCount++;
        _isNavigating = false;
      });
      ErrorHandlerService.logMessage('Retry attempt $_retryCount/$_maxRetries');
      _loadApp();
    } else {
      _showResetDialog();
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Load'),
        content: const Text(
          'We\'re having trouble loading your data. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _retryCount = 0;
                _isNavigating = false;
              });
              ErrorHandlerService.logMessage('User initiated final retry');
              _loadApp();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ErrorHandlerService.logMessage('User initiated data reset');
              await FirebaseUserPreferences.clearPreferences();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const BaseLanguageSelectorScreen(),
                ),
              );
            },
            child: const Text('Reset Setup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ErrorHandlerService.logMessage('User skipped to setup');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const BaseLanguageSelectorScreen(),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.brown.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 80, color: Colors.brown),
                  const SizedBox(height: 24),
                  Text(
                    'Connection Issue',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Please check your internet connection.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.brown.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _handleRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _retryCount > 0
                          ? 'Retry ($_retryCount/$_maxRetries)'
                          : 'Retry',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ErrorHandlerService.logMessage('User skipped to setup from error');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BaseLanguageSelectorScreen(),
                        ),
                      );
                    },
                    child: const Text('Skip to Setup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Loading state
    return Scaffold(
      backgroundColor: Colors.brown,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                _loadingStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This usually takes just a moment...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}