import 'package:flutter/material.dart';

/// Represents a single step in the tutorial
class TutorialStep {
  final String id;
  final String title;
  final String message;
  final GlobalKey? targetKey; // Key of the widget to highlight
  final Offset? targetPosition; // Manual position if no key
  final Size? targetSize; // Manual size if no key
  final TutorialStepPosition messagePosition;
  final IconData? icon;
  final String screen; // Which screen this step belongs to

  const TutorialStep({
    required this.id,
    required this.title,
    required this.message,
    this.targetKey,
    this.targetPosition,
    this.targetSize,
    this.messagePosition = TutorialStepPosition.bottom,
    this.icon,
    required this.screen,
  });

  /// Get the position and size of the target widget
  Rect? getTargetRect() {
    if (targetKey?.currentContext != null) {
      final RenderBox renderBox =
          targetKey!.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    } else if (targetPosition != null && targetSize != null) {
      return Rect.fromLTWH(
        targetPosition!.dx,
        targetPosition!.dy,
        targetSize!.width,
        targetSize!.height,
      );
    }
    return null;
  }

  /// Check if this step has a valid target
  bool get hasValidTarget =>
      (targetKey?.currentContext != null) ||
      (targetPosition != null && targetSize != null);
}

/// Where to position the message box relative to the target
enum TutorialStepPosition {
  top,
  bottom,
  center,
}

/// Tutorial configuration for different screens
class TutorialConfig {
  // Deck Selector Steps
  static const String deckSelectorWelcome = 'deck_welcome';
  static const String deckSelectorDeckCard = 'deck_card';
  static const String deckSelectorProgress = 'deck_progress';
  static const String deckSelectorForgotten = 'deck_forgotten';

  // Flashcard Screen Steps
  static const String flashcardSwipe = 'flashcard_swipe';
  static const String flashcardAdd = 'flashcard_add';
  static const String flashcardProgress = 'flashcard_progress';

  // Screen identifiers
  static const String screenDeckSelector = 'deck_selector';
  static const String screenFlashcard = 'flashcard';

  /// Get all tutorial steps with localized text
  static List<TutorialStep> getSteps(String language) {
    return [
      // Deck Selector Steps
      TutorialStep(
        id: deckSelectorWelcome,
        title: _getText(language, 'welcome_title'),
        message: _getText(language, 'welcome_message'),
        messagePosition: TutorialStepPosition.center,
        icon: Icons.waving_hand,
        screen: screenDeckSelector,
      ),
      TutorialStep(
        id: deckSelectorDeckCard,
        title: _getText(language, 'deck_card_title'),
        message: _getText(language, 'deck_card_message'),
        messagePosition: TutorialStepPosition.bottom,
        icon: Icons.style,
        screen: screenDeckSelector,
      ),
      TutorialStep(
        id: deckSelectorProgress,
        title: _getText(language, 'progress_title'),
        message: _getText(language, 'progress_message'),
        messagePosition: TutorialStepPosition.bottom,
        icon: Icons.analytics,
        screen: screenDeckSelector,
      ),
      TutorialStep(
        id: deckSelectorForgotten,
        title: _getText(language, 'forgotten_title'),
        message: _getText(language, 'forgotten_message'),
        messagePosition: TutorialStepPosition.bottom,
        icon: Icons.refresh,
        screen: screenDeckSelector,
      ),
      TutorialStep(
        id: flashcardSwipe,
        title: _getText(language, 'swipe_title'),
        message: _getText(language, 'swipe_message'),
        messagePosition: TutorialStepPosition.bottom,
        icon: Icons.swipe,
        screen: screenFlashcard,
      ),
      TutorialStep(
        id: flashcardAdd,
        title: _getText(language, 'add_title'),
        message: _getText(language, 'add_message'),
        messagePosition: TutorialStepPosition.top,
        icon: Icons.add_circle,
        screen: screenFlashcard,
      ),
      TutorialStep(
        id: flashcardProgress,
        title: _getText(language, 'track_title'),
        message: _getText(language, 'track_message'),
        messagePosition: TutorialStepPosition.bottom,
        icon: Icons.track_changes,
        screen: screenFlashcard,
      ),
    ];
  }

  /// Get localized text for tutorial steps
  static String _getText(String language, String key) {
    final isPortuguese = language == 'portuguese';

    final texts = {
      'welcome_title': isPortuguese ? 'Bem-vindo ao FlashLango!' : 'Welcome to FlashLango!',
      'welcome_message': isPortuguese
          ? 'Vamos fazer um tour rápido para você começar a aprender! 🎉'
          : 'Let\'s take a quick tour to get you started learning! 🎉',
      
      'deck_card_title': isPortuguese ? 'Baralhos de Estudo' : 'Study Decks',
      'deck_card_message': isPortuguese
          ? 'Toque em qualquer baralho para começar a aprender. Cada baralho tem um tópico como Animais, Cores, etc.'
          : 'Tap any deck to start learning. Each deck has a topic like Animals, Colors, etc.',
      
      'progress_title': isPortuguese ? 'Entenda seu Progresso' : 'Understanding Progress',
      'progress_message': isPortuguese
          ? 'Azul = Novo (não viu ainda)\nLaranja = Vencido (hora de revisar)\nVerde = Aprendendo (dominando!)'
          : 'Blue = New (haven\'t seen)\nOrange = Due (time to review)\nGreen = Learning (mastering!)',
      
      'forgotten_title': isPortuguese ? 'Cartas Esquecidas' : 'Forgotten Cards',
      'forgotten_message': isPortuguese
          ? 'Cartas que você errou aparecem aqui. Revise-as para movê-las de volta ao baralho!'
          : 'Cards you got wrong appear here. Review them to move them back to your deck!',
      
      'swipe_title': isPortuguese ? 'Deslize para Aprender' : 'Swipe to Learn',
      'swipe_message': isPortuguese
          ? 'Toque para virar a carta.\nDeslize para DIREITA ➡️ se souber\nDeslize para ESQUERDA ⬅️ se precisar praticar'
          : 'Tap to flip the card.\nSwipe RIGHT ➡️ if you know it\nSwipe LEFT ⬅️ if you need practice',
      
      'add_title': isPortuguese ? 'Crie suas Próprias Cartas' : 'Create Your Own Cards',
      'add_message': isPortuguese
          ? 'Crie flashcards personalizados com o botão +. Você também pode adicionar imagens!'
          : 'Create custom flashcards with the + button. You can add images too!',
      
      'track_title': isPortuguese ? 'Acompanhe seu Progresso' : 'Track Your Progress',
      'track_message': isPortuguese
          ? 'Seu progresso é salvo automaticamente. Estude a qualquer hora, em qualquer lugar!'
          : 'Your progress is saved automatically. Study anytime, anywhere!',
    };

    return texts[key] ?? key;
  }
}