import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/ui_language_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = context.read<UiLanguageProvider>().loc;

    // Check password match
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showError(loc.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Send verification email
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        try {
          await user.sendEmailVerification();
          
          if (!mounted) return;

          final dialogLoc = context.read<UiLanguageProvider>().loc;

          // Show success dialog with verification info
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Text(dialogLoc.accountCreated),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dialogLoc.accountCreatedSuccessfully,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(dialogLoc.verificationEmailSentTo),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.email ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    dialogLoc.pleaseCheckInboxToVerify,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                          size: 16, 
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogLoc.canStartUsingAppNow,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pop(); // Go back to login
                  },
                  child: Text(dialogLoc.continueToLogin),
                ),
              ],
            ),
          );
        } catch (e) {
          // If verification email fails, still allow registration
          debugPrint('Failed to send verification email: $e');
          
          if (!mounted) return;
          
          final errorLoc = context.read<UiLanguageProvider>().loc;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorLoc.accountCreatedButEmailFailed),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      final errorLoc = context.read<UiLanguageProvider>().loc;
      String errorMessage = errorLoc.registrationFailed;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = errorLoc.emailAlreadyInUse;
          break;
        case 'invalid-email':
          errorMessage = errorLoc.invalidEmail;
          break;
        case 'operation-not-allowed':
          errorMessage = errorLoc.operationNotAllowed;
          break;
        case 'weak-password':
          errorMessage = errorLoc.weakPassword;
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

    if (email.isEmpty) {
      _showError(loc.pleaseEnterEmailFirst);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError(loc.enterValidEmail);
      return;
    }

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

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      final successLoc = context.read<UiLanguageProvider>().loc;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(successLoc.emailSent),
            ],
          ),
          content: Text(
            '${successLoc.passwordResetEmailSent}\n\n$email\n\n${successLoc.checkInboxAndSpam}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(successLoc.ok),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      final errorLoc = context.read<UiLanguageProvider>().loc;
      String errorMessage = errorLoc.errorSendingResetEmail;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = errorLoc.noAccountFound;
          break;
        case 'invalid-email':
          errorMessage = errorLoc.invalidEmail;
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      _showError(errorMessage);
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.watch<UiLanguageProvider>().loc;

    return Scaffold(
      appBar: AppBar(title: Text(loc.createAccount)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_add,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  loc.joinFlashLango,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.startLearning,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: loc.password,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.enterAPassword;
                    }
                    if (value.length < 6) {
                      return loc.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: loc.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.confirmYourPassword;
                    }
                    if (value != _passwordController.text) {
                      return loc.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Register button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(loc.createAccount),
                      ),
                const SizedBox(height: 16),

                // Forgot password option
                TextButton.icon(
                  onPressed: _resetPassword,
                  icon: const Icon(Icons.help_outline, size: 20),
                  label: Text(loc.alreadyHaveAccountForgotPassword),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}