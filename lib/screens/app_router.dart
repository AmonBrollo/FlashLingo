import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firebase_user_preferences.dart';
import '../services/deck_loader.dart';
import '../services/loading_with_timeout.dart';
import '../services/error_handler_service.dart';
import '../services/app_state_service.dart';
import '../services/ui_language_provider.dart';
import 'login_screen.dart';
import 'base_language_selector_screen.dart';
import 'target_language_selector_screen.dart';
import 'deck_selector_screen.dart';

/// Enhanced AppRouter with navigation guards and state restoration
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  String _loadingStatus = '';
  bool _hasError = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Initialize loading status immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final loc = context.read<UiLanguageProvider>().loc;
        setState(() {
          _loadingStatus = loc.initializing;
        });
        _loadApp();
      }
    });
  }

  Future<void> _loadApp() async {
    if (_isNavigating) return;

    final loc = context.read<UiLanguageProvider>().loc;
    
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _loadingStatus = loc.loading;
    });

    await ErrorHandlerService.logMessage('AppRouter: Starting app load');

    try {
      final screen = await _determineStartScreen();
      
      if (!mounted) return;
      
      setState(() => _isNavigating = true);
      
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
    final loc = context.read<UiLanguageProvider>().loc;
    final errorStr = error.toString().toLowerCase();
    
    // Return localized error messages for known error types
    if (errorStr.contains('timeout')) {
      return loc.connectionTimeout;
    } else if (errorStr.contains('network')) {
      return loc.networkError;
    } else if (errorStr.contains('permission')) {
      return loc.permissionDenied;
    }
    return loc.unexpectedError;
  }

  Future<Widget> _determineStartScreen() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    try {
      // Step 1: Check authentication
      setState(() => _loadingStatus = loc.checkingAuthentication);
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
        setState(() => _loadingStatus = loc.refreshingData);
        await ErrorHandlerService.logMessage('Refreshing stale data');
        await appState.refreshData();
      }

      // Step 3: Load preferences
      setState(() => _loadingStatus = loc.loadingProgress);
      await ErrorHandlerService.logMessage('Step 2: Loading preferences');
      
      final prefs = await LoadingWithTimeout.execute(
        operation: () => FirebaseUserPreferences.loadPreferences(),
        timeout: const Duration(seconds: 8),
        operationName: 'Load preferences',
      );

      final baseLang = prefs['baseLanguage'];
      final targetLang = prefs['targetLanguage'];
      final deckKey = prefs['deckKey'];

      await ErrorHandlerService.logMessage(
        'Preferences: base=$baseLang, target=$targetLang, deck=$deckKey',
      );

      if (baseLang == null) {
        await ErrorHandlerService.logMessage('No base language, going to setup');
        return const BaseLanguageSelectorScreen();
      }
      
      if (targetLang == null) {
        await ErrorHandlerService.logMessage('No target language, going to setup');
        return TargetLanguageSelectorScreen(baseLanguage: baseLang);
      }

      // Step 4: Load decks
      setState(() => _loadingStatus = loc.loadingDecks);
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
        
        final errorLoc = context.read<UiLanguageProvider>().loc;
        
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    errorLoc.noDeckFound,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(errorLoc.checkInstallation),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _handleRetry(),
                    child: Text(errorLoc.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await ErrorHandlerService.logMessage('Loaded ${decks.length} decks');

      // Step 5: Navigate to appropriate screen
      if (deckKey != null && deckKey != 'forgotten') {
        final appState = context.read<AppStateService>();
        final timeSinceActive = appState.getTimeSinceLastActive();
        
        if (timeSinceActive != null && timeSinceActive.inMinutes < 10) {
          await ErrorHandlerService.logMessage('Recent activity, going to deck selector');
          return DeckSelectorScreen(
            baseLanguage: baseLang,
            targetLanguage: targetLang,
            decks: decks,
          );
        }
      }

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

      if (e.toString().contains('timeout') || e.toString().contains('network')) {
        try {
          final loc = context.read<UiLanguageProvider>().loc;
          setState(() => _loadingStatus = loc.usingOfflineData);
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

      await ErrorHandlerService.logMessage('Falling back to base language setup');
      return const BaseLanguageSelectorScreen();
    }
  }

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
    final loc = context.read<UiLanguageProvider>().loc;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.unableToLoad),
        content: Text(loc.havingTroubleLoading),
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
            child: Text(loc.tryAgain),
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
            child: Text(loc.resetSetup),
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
            child: Text(loc.continueText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    
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
                    loc.connectionIssue,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? loc.checkInternetConnection,
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
                          ? '${loc.retry} ($_retryCount/$_maxRetries)'
                          : loc.retry,
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
                    child: Text(loc.skipToSetup),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Loading screen
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
                _loadingStatus.isEmpty ? loc.initializing : _loadingStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.takesJustMoment,
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