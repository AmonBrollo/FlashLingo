import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/app_initialization_service.dart';
import '../services/local_image_service.dart';
import '../services/tutorial_service.dart';
import '../services/firebase_user_preferences.dart';
import '../services/deck_loader.dart';
import '../services/sync_service.dart';
import '../services/ui_language_provider.dart';
import 'app_router.dart';
import 'login_screen.dart';
import 'deck_selector_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isResendingVerification = false;
  bool _isManualSyncing = false;
  Map<String, dynamic>? _storageStats;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;
  SyncStatus _currentSyncStatus = SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
    _setupSyncStatusListener();
  }

  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    super.dispose();
  }

  void _setupSyncStatusListener() {
    _syncStatusSubscription = SyncService().syncStatus.listen((status) {
      if (mounted) {
        setState(() {
          _currentSyncStatus = status;
        });
      }
    });
  }

  Future<void> _loadStorageStats() async {
    try {
      final stats = await LocalImageService.getStorageStats();
      if (mounted) {
        setState(() {
          _storageStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading storage stats: $e');
    }
  }

  Future<void> _manualSync() async {
    if (_isManualSyncing) return;

    setState(() => _isManualSyncing = true);

    final loc = context.read<UiLanguageProvider>().loc;

    try {
      final result = await SyncService().syncNow();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(loc.syncCompleted),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result.reason ?? loc.syncFailed),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorLoc = context.read<UiLanguageProvider>().loc;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('${errorLoc.syncError}: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualSyncing = false);
      }
    }
  }

  Widget _buildSyncStatusIcon() {
    switch (_currentSyncStatus) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case SyncStatus.synced:
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red, size: 20);
      case SyncStatus.idle:
        if (SyncService().hasPendingChanges) {
          return const Icon(Icons.cloud_upload, color: Colors.orange, size: 20);
        }
        return const Icon(Icons.cloud_queue, color: Colors.grey, size: 20);
    }
  }

  String _getSyncStatusText() {
    final loc = context.read<UiLanguageProvider>().loc;
    
    switch (_currentSyncStatus) {
      case SyncStatus.syncing:
        return loc.syncing;
      case SyncStatus.synced:
        return SyncService().getSyncStatusText();
      case SyncStatus.error:
        return loc.syncError;
      case SyncStatus.idle:
        if (SyncService().hasPendingChanges) {
          return loc.changesPending;
        }
        return SyncService().getSyncStatusText();
    }
  }

  Color _getSyncStatusColor() {
    switch (_currentSyncStatus) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.idle:
        if (SyncService().hasPendingChanges) {
          return Colors.orange;
        }
        return Colors.grey;
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResendingVerification = true);

    final loc = context.read<UiLanguageProvider>().loc;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.verificationEmailSent),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final errorLoc = context.read<UiLanguageProvider>().loc;
        String errorMessage = errorLoc.failedToSendVerificationEmail;

        switch (e.code) {
          case 'too-many-requests':
            errorMessage = errorLoc.tooManyEmailRequests;
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResendingVerification = false);
      }
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() => _isLoading = true);

    final loc = context.read<UiLanguageProvider>().loc;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (mounted) {
          setState(() {});

          if (updatedUser?.emailVerified == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.emailVerifiedSuccessfully),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.emailNotVerifiedYet),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final errorLoc = context.read<UiLanguageProvider>().loc;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${errorLoc.errorCheckingVerification}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _replayTutorial() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    try {
      // Reset tutorial state
      await TutorialService.resetTutorial();

      if (!mounted) return;

      // Show confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.school, color: Colors.brown, size: 28),
              const SizedBox(width: 12),
              Text(loc.viewTutorial),
            ],
          ),
          content: Text(loc.tutorialWillStart),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
              ),
              child: Text(loc.startTutorial),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Load decks and navigate to deck selector with tutorial
      final decks = await DeckLoader.loadDecks();
      final prefs = await FirebaseUserPreferences.loadPreferences();

      final baseLanguage = prefs['baseLanguage'] ?? 'english';
      final targetLanguage = prefs['targetLanguage'] ?? 'hungarian';

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeckSelectorScreen(
            baseLanguage: baseLanguage,
            targetLanguage: targetLanguage,
            decks: decks,
            showTutorial: true, // Force show tutorial
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorLoc = context.read<UiLanguageProvider>().loc;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${errorLoc.errorStartingTutorial}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.logout),
        content: Text(loc.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.brown),
            child: Text(loc.logout),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppRouter()),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorLoc = context.read<UiLanguageProvider>().loc;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${errorLoc.errorLoggingOut}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _login(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _resetProgress() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.resetProgress),
        content: Text(
          '${loc.areYouSure} ${loc.cannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.resetProgress),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await AppInitializationService.clearLocalData();

        if (mounted) {
          final successLoc = context.read<UiLanguageProvider>().loc;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successLoc.progressResetSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorLoc = context.read<UiLanguageProvider>().loc;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${errorLoc.errorResettingProgress}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _resetAllData() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.resetAllData),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.thisWillPermanentlyDelete,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(loc.learningProgressAndStats),
            Text(loc.languageAndDeckPrefs),
            Text(loc.allFlashcardImages),
            Text(loc.accountPreferences),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                loc.thisCannotBeUndone,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_storageStats != null)
              Text(
                loc.freeUpStorage(_storageStats!['totalSizeMB'].toString()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: Text(loc.deleteAllData),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await AppInitializationService.clearLocalData();
        await LocalImageService.clearAllImages();
        await _loadStorageStats();

        if (mounted) {
          final successLoc = context.read<UiLanguageProvider>().loc;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successLoc.allDataReset),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          final errorLoc = context.read<UiLanguageProvider>().loc;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${errorLoc.errorResettingAllData}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _clearImages() async {
    final loc = context.read<UiLanguageProvider>().loc;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.clearAllImages),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.areYouSure} ${loc.cannotBeUndone}',
            ),
            const SizedBox(height: 8),
            if (_storageStats != null) ...[
              Text(
                loc.freeUpStorage(_storageStats!['totalSizeMB'].toString()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.deleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await LocalImageService.clearAllImages();
        await _loadStorageStats();

        if (mounted) {
          final successLoc = context.read<UiLanguageProvider>().loc;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successLoc.imagesCleared),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorLoc = context.read<UiLanguageProvider>().loc;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${errorLoc.errorClearingImages}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _cleanupImages() async {
    setState(() => _isLoading = true);

    final loc = context.read<UiLanguageProvider>().loc;

    try {
      await LocalImageService.cleanupOrphanedImages();
      await _loadStorageStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.cleanupCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorLoc = context.read<UiLanguageProvider>().loc;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${errorLoc.errorDuringCleanup}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;
    final isEmailVerified = user?.emailVerified ?? false;
    final loc = context.watch<UiLanguageProvider>().loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profile),
        backgroundColor: Colors.brown,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Information Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isAnonymous
                                    ? Icons.person_outline
                                    : Icons.person,
                                size: 32,
                                color: Colors.brown,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAnonymous
                                          ? loc.anonymousUser
                                          : loc.loggedIn,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (!isAnonymous && user?.email != null)
                                      Text(
                                        user!.email!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Email Verification Status
                          if (!isAnonymous) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  isEmailVerified
                                      ? Icons.verified
                                      : Icons.warning_amber,
                                  color: isEmailVerified
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isEmailVerified
                                        ? loc.emailVerified
                                        : loc.emailNotVerified,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isEmailVerified
                                          ? Colors.green[700]
                                          : Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isEmailVerified) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.pleaseVerifyEmail,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _isResendingVerification
                                                ? null
                                                : _resendVerificationEmail,
                                            icon: _isResendingVerification
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.email,
                                                    size: 18),
                                            label: Text(loc.resendEmail),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.orange[900],
                                              side: BorderSide(
                                                color: Colors.orange[300]!,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                _checkEmailVerification,
                                            icon: const Icon(Icons.refresh,
                                                size: 18),
                                            label: Text(loc.iVerified),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orange[700],
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: 16),

                          // Auth Button
                          SizedBox(
                            width: double.infinity,
                            child: isAnonymous
                                ? ElevatedButton.icon(
                                    onPressed: () => _login(context),
                                    icon: const Icon(Icons.login),
                                    label: Text(loc.signInToSaveProgress),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  )
                                : OutlinedButton.icon(
                                    onPressed: () => _logout(context),
                                    icon: const Icon(Icons.logout),
                                    label: Text(loc.signOut),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.brown,
                                      side: const BorderSide(
                                        color: Colors.brown,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),

                          // Info for anonymous users
                          if (isAnonymous) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      loc.signInToSync,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sync Status Card (only show for logged-in users)
                  if (!isAnonymous)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildSyncStatusIcon(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.syncStatus,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getSyncStatusText(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _getSyncStatusColor(),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isManualSyncing ||
                                          _currentSyncStatus ==
                                              SyncStatus.syncing
                                      ? null
                                      : _manualSync,
                                  icon: _isManualSyncing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.sync, size: 18),
                                  label: Text(loc.syncNow),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue[100]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      loc.progressSyncsAutomatically,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Storage Information Card
                  if (_storageStats != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.storageUsage,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${loc.images}:'),
                                Text('${_storageStats!['fileCount']} ${loc.files}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${loc.storageUsed}:'),
                                Text('${_storageStats!['totalSizeMB']} MB'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Tutorial Section
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: Colors.brown),
                    ),
                    title: Text(
                      loc.viewTutorial,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(loc.learnHowToUse),
                    trailing: const Icon(Icons.play_circle_outline),
                    onTap: _replayTutorial,
                  ),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 24),

                  Text(
                    loc.dataManagement,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Image Management Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cleanupImages,
                      icon: const Icon(Icons.cleaning_services),
                      label: Text(loc.cleanupUnusedImages),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        backgroundColor: Colors.blue[50],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearImages,
                      icon: const Icon(Icons.delete_sweep),
                      label: Text(loc.clearAllImages),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        backgroundColor: Colors.orange[50],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Reset
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resetProgress,
                      icon: const Icon(Icons.refresh),
                      label: Text(loc.resetProgress),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red[50],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reset All Data
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resetAllData,
                      icon: const Icon(Icons.warning),
                      label: Text(loc.resetAllData),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red[700],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      loc.flashLango,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}