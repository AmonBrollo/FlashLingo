import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/ui_language_provider.dart';
import 'register_screen.dart';
import 'app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final loc = context.read<UiLanguageProvider>().loc;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Check if email is verified
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        // Show info but allow them to continue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.pleaseVerifyEmail),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppRouter()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = loc.loginFailed;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = loc.noAccountFound;
          break;
        case 'wrong-password':
          errorMessage = loc.incorrectPassword;
          break;
        case 'invalid-email':
          errorMessage = loc.invalidEmail;
          break;
        case 'user-disabled':
          errorMessage = loc.accountDisabled;
          break;
        case 'too-many-requests':
          errorMessage = loc.tooManyRequests;
          break;
        case 'invalid-credential':
          errorMessage = loc.invalidCredential;
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final loc = context.read<UiLanguageProvider>().loc;
    final email = _emailController.text.trim();

    // Validate email first
    if (email.isEmpty) {
      _showError(loc.pleaseEnterEmailFirst);
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError(loc.enterValidEmail);
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.resetPassword),
        content: Text(
          '${loc.passwordResetLinkWillBeSent}\n\n$email\n\n${loc.checkEmailInboxAndSpam}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.sendResetEmail),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final dialogLoc = context.read<UiLanguageProvider>().loc;

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(dialogLoc.emailSent),
            ],
          ),
          content: Text(
            '${dialogLoc.passwordResetEmailSent}\n\n$email\n\n${dialogLoc.checkInboxAndSpam}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(dialogLoc.ok),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final errorLoc = context.read<UiLanguageProvider>().loc;
      String errorMessage = errorLoc.errorSendingResetEmail;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = errorLoc.noAccountFound;
          break;
        case 'invalid-email':
          errorMessage = errorLoc.invalidEmail;
          break;
        case 'too-many-requests':
          errorMessage = errorLoc.tooManyRequests;
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      _showErrorDialog(errorLoc.passwordResetFailed, errorMessage);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      final errorLoc = context.read<UiLanguageProvider>().loc;
      _showErrorDialog(
        errorLoc.error,
        errorLoc.unexpectedError,
      );
    }
  }

  Future<void> _skipLogin() async {
    final loc = context.read<UiLanguageProvider>().loc;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppRouter()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? loc.anonymousSignInFailed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    final loc = context.read<UiLanguageProvider>().loc;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.watch<UiLanguageProvider>().loc;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.school, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  loc.flashLango,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.welcomeBack,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: loc.email,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.enterEmail;
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return loc.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: loc.password,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.enterPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password (aligned right)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text(loc.forgotPassword),
                  ),
                ),
                const SizedBox(height: 16),

                // Login button or loader
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(loc.login),
                      ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        loc.or,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Register link
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(loc.createNewAccount),
                ),
                const SizedBox(height: 12),

                // Skip login
                TextButton(
                  onPressed: _skipLogin,
                  child: Text(loc.continueWithoutAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}