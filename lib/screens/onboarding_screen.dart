import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ui_language_provider.dart';
import '../l10n/app_localizations.dart';

/// Key used to gate the onboarding. Intentionally separate from
/// `tutorial_completed` so the interactive deck tutorial stays independent.
const String kOnboardingCompletedKey = 'onboarding_completed';

/// Returns true when the onboarding has never been shown.
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(kOnboardingCompletedKey) ?? false);
}

/// Marks onboarding as done so it never shows again automatically.
/// Calling this with [reset] = true lets the profile screen replay it.
Future<void> setOnboardingCompleted({bool reset = false}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompletedKey, !reset);
}

class OnboardingScreen extends StatefulWidget {
  /// Called once the user taps "Get Started" or "Skip".
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await setOnboardingCompleted();
    widget.onComplete();
  }

  Future<void> _skip() async {
    await setOnboardingCompleted();
    widget.onComplete();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<UiLanguageProvider>().loc;
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    loc.skip,
                    style: TextStyle(
                      color: Colors.brown.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OnboardingPage(
                    icon: Icons.bolt,
                    iconColor: Colors.amber.shade600,
                    iconBackground: Colors.amber.shade50,
                    title: loc.onboardingTitle1,
                    body: loc.onboardingBody1,
                    detail: null,
                  ),
                  _OnboardingPage(
                    icon: Icons.style_outlined,
                    iconColor: Colors.brown,
                    iconBackground: Colors.brown.shade50,
                    title: loc.onboardingTitle2,
                    body: loc.onboardingBody2,
                    detail: _CardActions(loc: loc),
                  ),
                  _OnboardingPage(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: Colors.indigo,
                    iconBackground: Colors.indigo.shade50,
                    title: loc.onboardingTitle3,
                    body: loc.onboardingBody3,
                    detail: _BoxLadder(loc: loc),
                  ),
                  _OnboardingPage(
                    icon: Icons.today_outlined,
                    iconColor: Colors.green.shade700,
                    iconBackground: Colors.green.shade50,
                    title: loc.onboardingTitle4,
                    body: loc.onboardingBody4,
                    detail: null,
                  ),
                ],
              ),
            ),

            // ── Page indicators ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.brown
                          : Colors.brown.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ── CTA button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastPage ? loc.onboardingGetStarted : loc.next,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual page layout ────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String body;
  final Widget? detail;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Body
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),

          // Optional inline detail widget
          if (detail != null) ...[
            const SizedBox(height: 28),
            detail!,
          ],
        ],
      ),
    );
  }
}

// ── Page 2 detail: tap / swipe action chips ───────────────────────────────────

class _CardActions extends StatelessWidget {
  final AppLocalizations loc;
  const _CardActions({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionRow(
          icon: Icons.touch_app_outlined,
          color: Colors.brown,
          label: loc.onboardingActionTap,
        ),
        const SizedBox(height: 10),
        _ActionRow(
          icon: Icons.arrow_forward,
          color: Colors.green.shade700,
          label: loc.onboardingActionSwipeRight,
        ),
        const SizedBox(height: 10),
        _ActionRow(
          icon: Icons.arrow_back,
          color: Colors.orange.shade700,
          label: loc.onboardingActionSwipeLeft,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _ActionRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3 detail: Leitner box ladder ────────────────────────────────────────

class _BoxLadder extends StatelessWidget {
  final AppLocalizations loc;
  const _BoxLadder({required this.loc});

  // (box number, interval label, fill fraction for the progress bar)
  static const _boxes = [
    (1, '1d', 0.15),
    (2, '2d', 0.30),
    (3, '4d', 0.50),
    (4, '7d', 0.70),
    (5, '14d', 1.00),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _boxes.map((b) {
        final (box, interval, fill) = b;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              // Box label
              SizedBox(
                width: 48,
                child: Text(
                  'Box $box',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Progress bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.lerp(
                        Colors.orange.shade400,
                        Colors.green.shade600,
                        fill,
                      )!,
                    ),
                  ),
                ),
              ),
              // Interval label
              SizedBox(
                width: 36,
                child: Text(
                  interval,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}