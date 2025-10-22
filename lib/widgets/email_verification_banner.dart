import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isResending = false;
  bool _emailSent = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0) return;

    setState(() => _isResending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (mounted) {
          setState(() {
            _emailSent = true;
            _cooldownSeconds = 60;
          });

          // Start cooldown timer
          _cooldownTimer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              if (mounted) {
                setState(() {
                  _cooldownSeconds--;
                  if (_cooldownSeconds <= 0) {
                    timer.cancel();
                    _emailSent = false;
                  }
                });
              } else {
                timer.cancel();
              }
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Check your inbox.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to send verification email';
        
        switch (e.code) {
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
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
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _checkVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser?.emailVerified == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          // Force rebuild to hide banner
          setState(() {});
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Don't show banner if user is anonymous, verified, or not logged in
    if (user == null || user.isAnonymous || user.emailVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(
          bottom: BorderSide(color: Colors.orange[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mail_outline,
            color: Colors.orange[900],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please verify your email',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _emailSent
                      ? 'Email sent! Check your inbox.'
                      : 'Check your inbox for the verification link.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isResending)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_cooldownSeconds > 0)
            Text(
              '${_cooldownSeconds}s',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _checkVerification,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[900],
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'I verified',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _resendVerificationEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[900],
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Resend',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}