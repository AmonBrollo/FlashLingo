import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_user_preferences.dart';
import '../services/repetition_service.dart';
import '../services/deck_loader.dart';
import '../services/loading_with_timeout.dart';
import '../models/flashcard_deck.dart';
import 'login_screen.dart';
import 'base_language_selector_screen.dart';
import 'target_language_selector_screen.dart';
import 'flashcard_screen.dart';

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
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  Future<void> _loadApp() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _loadingStatus = 'Initializing...';
    });

    try {
      final screen = await _determineStartScreen();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<Widget> _determineStartScreen() async {
    try {
      // Step 1: Check authentication (with timeout)
      setState(() => _loadingStatus = 'Checking authentication...');
      final user = await LoadingWithTimeout.execute(
        operation: () async => FirebaseAuth.instance.currentUser,
        timeout: const Duration(seconds: 5),
        operationName: 'Authentication check',
      );

      if (user == null) return const LoginScreen();

      // Step 2: Load preferences (with timeout)
      setState(() => _loadingStatus = 'Loading preferences...');
      final prefs = await LoadingWithTimeout.execute(
        operation: () => FirebaseUserPreferences.loadPreferences(),
        timeout: const Duration(seconds: 8),
        operationName: 'Load preferences',
      );

      final baseLang = prefs['baseLanguage'];
      final targetLang = prefs['targetLanguage'];
      final deckKey = prefs['deckKey'];

      // Validate preferences
      if (baseLang == null) return const BaseLanguageSelectorScreen();
      if (targetLang == null) {
        return TargetLanguageSelectorScreen(baseLanguage: baseLang);
      }

      // Step 3: Load decks (with timeout)
      setState(() => _loadingStatus = 'Loading flashcard decks...');
      final decks = await LoadingWithTimeout.execute(
        operation: () => DeckLoader.loadDecks(),
        timeout: const Duration(seconds: 8),
        operationName: 'Load decks',
      );

      if (decks.isEmpty) {
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'No flashcard decks found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Please check your installation'),
              ],
            ),
          ),
        );
      }

      // Step 4: Select appropriate deck
      FlashcardDeck initialDeck;
      if (deckKey != null) {
        initialDeck = decks.firstWhere(
          (d) => d.topicKey == deckKey,
          orElse: () => decks.first,
        );
      } else {
        initialDeck = decks.first;
      }

      // Step 5: Initialize repetition service (with timeout)
      setState(() => _loadingStatus = 'Preparing your progress...');
      try {
        await LoadingWithTimeout.execute(
          operation: () async {
            final repetitionService = RepetitionService();
            await repetitionService.initialize();
            await repetitionService.preloadProgress(initialDeck.cards);
          },
          timeout: const Duration(seconds: 10),
          operationName: 'Initialize repetition service',
        );
      } catch (e) {
        print('Warning: Could not preload progress: $e');
        // Continue without preloaded progress
      }

      // Success! Navigate to flashcards
      return FlashcardScreen(
        flashcards: initialDeck.cards,
        baseLanguage: baseLang,
        targetLanguage: targetLang,
        topicKey: initialDeck.topicKey,
      );
    } catch (e) {
      print('Error determining start screen: $e');

      // If this is a timeout or network error, try to use cached data
      if (e.toString().contains('timeout') ||
          e.toString().contains('network')) {
        try {
          // Try to recover with local-only data
          setState(() => _loadingStatus = 'Using offline data...');
          return await _loadWithLocalDataOnly();
        } catch (localError) {
          print('Local data recovery also failed: $localError');
        }
      }

      // Complete fallback
      return const BaseLanguageSelectorScreen();
    }
  }

  /// Attempt to load using only local data (no Firebase calls)
  Future<Widget> _loadWithLocalDataOnly() async {
    final prefs = await FirebaseUserPreferences.loadPreferencesLocal();
    final baseLang = prefs['baseLanguage'];
    final targetLang = prefs['targetLanguage'];

    if (baseLang == null || targetLang == null) {
      return const BaseLanguageSelectorScreen();
    }

    final decks = await DeckLoader.loadDecks();
    if (decks.isEmpty) {
      return const BaseLanguageSelectorScreen();
    }

    return FlashcardScreen(
      flashcards: decks.first.cards,
      baseLanguage: baseLang,
      targetLanguage: targetLang,
      topicKey: decks.first.topicKey,
    );
  }

  void _handleRetry() {
    if (_retryCount < _maxRetries) {
      setState(() => _retryCount++);
      _loadApp();
    } else {
      // Max retries reached, offer reset
      _showResetDialog();
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Load'),
        content: const Text(
          'We\'re having trouble loading your data. Would you like to:\n\n'
          '1. Try one more time\n'
          '2. Reset your setup and start fresh\n'
          '3. Continue with basic setup',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _retryCount = 0);
              _loadApp();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseUserPreferences.clearPreferences().then((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BaseLanguageSelectorScreen(),
                  ),
                );
              });
            },
            child: const Text('Reset Setup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
                    'We\'re having trouble loading your data.\n'
                    'Please check your internet connection.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.brown.shade700,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Error: ${_errorMessage!.length > 100 ? "${_errorMessage!.substring(0, 100)}..." : _errorMessage}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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
