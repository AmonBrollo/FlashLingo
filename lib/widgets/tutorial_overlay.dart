import 'package:flutter/material.dart';
import '../models/tutorial_step.dart';
import '../services/tutorial_service.dart';

/// Overlay widget that displays tutorial steps with spotlight effect
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final String language;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
    required this.language,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Log tutorial start
    TutorialService.logTutorialEvent('started');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  TutorialStep get currentStep => widget.steps[_currentStepIndex];
  bool get isFirstStep => _currentStepIndex == 0;
  bool get isLastStep => _currentStepIndex == widget.steps.length - 1;
  double get progress => (_currentStepIndex + 1) / widget.steps.length;

  void _nextStep() {
    if (isLastStep) {
      _completeTutorial();
    } else {
      setState(() {
        _currentStepIndex++;
      });
      TutorialService.saveCurrentStep(_currentStepIndex);
      TutorialService.logTutorialEvent('step_completed', stepIndex: _currentStepIndex);
      _animationController.forward(from: 0);
    }
  }

  void _previousStep() {
    if (!isFirstStep) {
      setState(() {
        _currentStepIndex--;
      });
      TutorialService.saveCurrentStep(_currentStepIndex);
      _animationController.forward(from: 0);
    }
  }

  void _completeTutorial() async {
    await TutorialService.completeTutorial();
    widget.onComplete();
  }

  void _skipTutorial() async {
    await TutorialService.skipTutorial();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = currentStep.getTargetRect();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dimmed background with spotlight
          CustomPaint(
            size: Size.infinite,
            painter: SpotlightPainter(
              targetRect: targetRect,
              opacity: 0.85,
            ),
          ),

          // Tutorial content
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildTutorialContent(targetRect),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildSkipButton(),
          ),

          // Progress bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildProgressBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialContent(Rect? targetRect) {
    final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine message position
    double? top;
    double? bottom;

    if (targetRect != null) {
      if (currentStep.messagePosition == TutorialStepPosition.top) {
        bottom = screenHeight - targetRect.top + 20;
      } else if (currentStep.messagePosition == TutorialStepPosition.bottom) {
        top = targetRect.bottom + 20;
      } else {
        // Center
        top = screenHeight / 2 - 100;
      }
    } else {
      // No target, center the message
      top = screenHeight / 2 - 100;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: 24,
      right: 24,
      child: _buildMessageCard(),
    );
  }

  Widget _buildMessageCard() {
    final isPortuguese = widget.language == 'portuguese';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title
          Row(
            children: [
              if (currentStep.icon != null) ...[
                Icon(
                  currentStep.icon,
                  color: Colors.brown,
                  size: 28,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  currentStep.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            currentStep.message,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              if (!isFirstStep)
                TextButton.icon(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(isPortuguese ? 'Anterior' : 'Previous'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                )
              else
                const SizedBox(width: 80),

              // Step indicator
              Text(
                '${_currentStepIndex + 1}/${widget.steps.length}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Next button
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLastStep
                          ? (isPortuguese ? 'Concluir' : 'Finish')
                          : (isPortuguese ? 'Próximo' : 'Next'),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isLastStep ? Icons.check : Icons.arrow_forward,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    final isPortuguese = widget.language == 'portuguese';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: _skipTutorial,
        icon: const Icon(Icons.close, size: 18),
        label: Text(isPortuguese ? 'Pular' : 'Skip'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.brown),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% ${widget.language == 'portuguese' ? 'completo' : 'complete'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the spotlight effect
class SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double opacity;

  SpotlightPainter({this.targetRect, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      // Add rounded rectangle hole for the spotlight
      final spotlightRect = RRect.fromRectAndRadius(
        targetRect!.inflate(8), // Add padding around target
        const Radius.circular(12),
      );
      path.addRRect(spotlightRect);
      path.fillType = PathFillType.evenOdd;
    }

    canvas.drawPath(path, paint);

    // Draw spotlight border
    if (targetRect != null) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final spotlightRect = RRect.fromRectAndRadius(
        targetRect!.inflate(8),
        const Radius.circular(12),
      );
      canvas.drawRRect(spotlightRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect || oldDelegate.opacity != opacity;
}