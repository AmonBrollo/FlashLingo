import 'language.dart';
import 'languages/en.dart';
import 'languages/pt.dart';

/// Main localization class
/// Provides all translated strings based on the selected language
class AppLocalizations {
  final Language language;

  AppLocalizations(this.language);

  /// Create from language code (supports both ISO and legacy codes)
  factory AppLocalizations.fromCode(String? code) {
    final lang = AppLanguages.getLanguageOrDefault(code);
    return AppLocalizations(lang);
  }

  /// Quick access - create from code
  static AppLocalizations of(String? languageCode) {
    return AppLocalizations.fromCode(languageCode);
  }

  // Navigation & Screens
  String get selectTargetLanguage => _getString(
        pt: PortugueseStrings.selectTargetLanguage,
        en: EnglishStrings.selectTargetLanguage,
      );

  String get selectDeck => _getString(
        pt: PortugueseStrings.selectDeck,
        en: EnglishStrings.selectDeck,
      );

  String get profile => _getString(
        pt: PortugueseStrings.profile,
        en: EnglishStrings.profile,
      );

  String get review => _getString(
        pt: PortugueseStrings.review,
        en: EnglishStrings.review,
      );

  String get reviewProgress => _getString(
        pt: PortugueseStrings.reviewProgress,
        en: EnglishStrings.reviewProgress,
      );

  // Flashcards
  String get addFlashcard => _getString(
        pt: PortugueseStrings.addFlashcard,
        en: EnglishStrings.addFlashcard,
      );

  String get addFlashcardTitle => _getString(
        pt: PortugueseStrings.addFlashcardTitle,
        en: EnglishStrings.addFlashcardTitle,
      );

  String get noImageYet => _getString(
        pt: PortugueseStrings.noImageYet,
        en: EnglishStrings.noImageYet,
      );

  String get finishedDeck => _getString(
        pt: PortugueseStrings.finishedDeck,
        en: EnglishStrings.finishedDeck,
      );

  String get tapToFlip => _getString(
        pt: PortugueseStrings.tapToFlip,
        en: EnglishStrings.tapToFlip,
      );

  String get swipeRight => _getString(
        pt: PortugueseStrings.swipeRight,
        en: EnglishStrings.swipeRight,
      );

  String get swipeLeft => _getString(
        pt: PortugueseStrings.swipeLeft,
        en: EnglishStrings.swipeLeft,
      );

  // Input Labels
  String get enterEnglishWord => _getString(
        pt: PortugueseStrings.enterEnglishWord,
        en: EnglishStrings.enterEnglishWord,
      );

  String get enterPortugueseWord => _getString(
        pt: PortugueseStrings.enterPortugueseWord,
        en: EnglishStrings.enterPortugueseWord,
      );

  String get enterHungarianWord => _getString(
        pt: PortugueseStrings.enterHungarianWord,
        en: EnglishStrings.enterHungarianWord,
      );

  String get enterWord => _getString(
        pt: PortugueseStrings.enterWord,
        en: EnglishStrings.enterWord,
      );

  /// Get input label for a specific language
  String getInputLabel(String languageCode) {
    final lang = AppLanguages.getLanguage(languageCode);
    if (lang == null) return enterWord;

    switch (lang.code) {
      case 'en':
        return enterEnglishWord;
      case 'pt':
        return enterPortugueseWord;
      case 'hu':
        return enterHungarianWord;
      default:
        return enterWord;
    }
  }

  // Status & Progress
  String get limitReached => _getString(
        pt: PortugueseStrings.limitReached,
        en: EnglishStrings.limitReached,
      );

  String get newCard => _getString(
        pt: PortugueseStrings.newCard,
        en: EnglishStrings.newCard,
      );

  String get dueCard => _getString(
        pt: PortugueseStrings.dueCard,
        en: EnglishStrings.dueCard,
      );

  String get learningCard => _getString(
        pt: PortugueseStrings.learningCard,
        en: EnglishStrings.learningCard,
      );

  String get forgottenCards => _getString(
        pt: PortugueseStrings.forgottenCards,
        en: EnglishStrings.forgottenCards,
      );

  // Actions
  String get add => _getString(
        pt: PortugueseStrings.add,
        en: EnglishStrings.add,
      );

  String get cancel => _getString(
        pt: PortugueseStrings.cancel,
        en: EnglishStrings.cancel,
      );

  String get delete => _getString(
        pt: PortugueseStrings.delete,
        en: EnglishStrings.delete,
      );

  String get save => _getString(
        pt: PortugueseStrings.save,
        en: EnglishStrings.save,
      );

  String get edit => _getString(
        pt: PortugueseStrings.edit,
        en: EnglishStrings.edit,
      );

  String get done => _getString(
        pt: PortugueseStrings.done,
        en: EnglishStrings.done,
      );

  String get skip => _getString(
        pt: PortugueseStrings.skip,
        en: EnglishStrings.skip,
      );

  String get next => _getString(
        pt: PortugueseStrings.next,
        en: EnglishStrings.next,
      );

  String get previous => _getString(
        pt: PortugueseStrings.previous,
        en: EnglishStrings.previous,
      );

  String get finish => _getString(
        pt: PortugueseStrings.finish,
        en: EnglishStrings.finish,
      );

  String get retry => _getString(
        pt: PortugueseStrings.retry,
        en: EnglishStrings.retry,
      );

  String get logout => _getString(
        pt: PortugueseStrings.logout,
        en: EnglishStrings.logout,
      );

  String get login => _getString(
        pt: PortugueseStrings.login,
        en: EnglishStrings.login,
      );

  // Messages
  String get loading => _getString(
        pt: PortugueseStrings.loading,
        en: EnglishStrings.loading,
      );

  String get error => _getString(
        pt: PortugueseStrings.error,
        en: EnglishStrings.error,
      );

  String get success => _getString(
        pt: PortugueseStrings.success,
        en: EnglishStrings.success,
      );

  String get noData => _getString(
        pt: PortugueseStrings.noData,
        en: EnglishStrings.noData,
      );

  String get tryAgain => _getString(
        pt: PortugueseStrings.tryAgain,
        en: EnglishStrings.tryAgain,
      );

  // Dynamic strings
  String comeBackIn(int hours, int minutes) {
    return language.code == 'pt'
        ? PortugueseStrings.comeBackIn(hours, minutes)
        : EnglishStrings.comeBackIn(hours, minutes);
  }

  String reviewLevel(int level) {
    return language.code == 'pt'
        ? PortugueseStrings.reviewLevel(level)
        : EnglishStrings.reviewLevel(level);
  }

  String cardsCount(int current, int total) {
    return language.code == 'pt'
        ? PortugueseStrings.cardsCount(current, total)
        : EnglishStrings.cardsCount(current, total);
  }

  String reviewCards(int count) {
    return language.code == 'pt'
        ? PortugueseStrings.reviewCards(count)
        : EnglishStrings.reviewCards(count);
  }

  // Tutorial
  String get viewTutorial => _getString(
        pt: PortugueseStrings.viewTutorial,
        en: EnglishStrings.viewTutorial,
      );

  String get learnHowToUse => _getString(
        pt: PortugueseStrings.learnHowToUse,
        en: EnglishStrings.learnHowToUse,
      );

  String get startTutorial => _getString(
        pt: PortugueseStrings.startTutorial,
        en: EnglishStrings.startTutorial,
      );

  String get tutorialWillStart => _getString(
        pt: PortugueseStrings.tutorialWillStart,
        en: EnglishStrings.tutorialWillStart,
      );

  // Profile
  String get anonymousUser => _getString(
        pt: PortugueseStrings.anonymousUser,
        en: EnglishStrings.anonymousUser,
      );

  String get loggedIn => _getString(
        pt: PortugueseStrings.loggedIn,
        en: EnglishStrings.loggedIn,
      );

  String get signInToSaveProgress => _getString(
        pt: PortugueseStrings.signInToSaveProgress,
        en: EnglishStrings.signInToSaveProgress,
      );

  String get signOut => _getString(
        pt: PortugueseStrings.signOut,
        en: EnglishStrings.signOut,
      );

  String get emailVerified => _getString(
        pt: PortugueseStrings.emailVerified,
        en: EnglishStrings.emailVerified,
      );

  String get emailNotVerified => _getString(
        pt: PortugueseStrings.emailNotVerified,
        en: EnglishStrings.emailNotVerified,
      );

  String get resendEmail => _getString(
        pt: PortugueseStrings.resendEmail,
        en: EnglishStrings.resendEmail,
      );

  String get iVerified => _getString(
        pt: PortugueseStrings.iVerified,
        en: EnglishStrings.iVerified,
      );

  // Data Management
  String get dataManagement => _getString(
        pt: PortugueseStrings.dataManagement,
        en: EnglishStrings.dataManagement,
      );

  String get resetProgress => _getString(
        pt: PortugueseStrings.resetProgress,
        en: EnglishStrings.resetProgress,
      );

  String get resetAllData => _getString(
        pt: PortugueseStrings.resetAllData,
        en: EnglishStrings.resetAllData,
      );

  String get clearAllImages => _getString(
        pt: PortugueseStrings.clearAllImages,
        en: EnglishStrings.clearAllImages,
      );

  String get cleanupUnusedImages => _getString(
        pt: PortugueseStrings.cleanupUnusedImages,
        en: EnglishStrings.cleanupUnusedImages,
      );

  String get storageUsage => _getString(
        pt: PortugueseStrings.storageUsage,
        en: EnglishStrings.storageUsage,
      );

  // Confirmation Messages
  String get areYouSure => _getString(
        pt: PortugueseStrings.areYouSure,
        en: EnglishStrings.areYouSure,
      );

  String get cannotBeUndone => _getString(
        pt: PortugueseStrings.cannotBeUndone,
        en: EnglishStrings.cannotBeUndone,
      );

  String get logoutConfirm => _getString(
        pt: PortugueseStrings.logoutConfirm,
        en: EnglishStrings.logoutConfirm,
      );

  // Deck Selector
  String get loadingProgress => _getString(
        pt: PortugueseStrings.loadingProgress,
        en: EnglishStrings.loadingProgress,
      );

  String get couldNotLoadProgress => _getString(
        pt: PortugueseStrings.couldNotLoadProgress,
        en: EnglishStrings.couldNotLoadProgress,
      );

  String get decksStillAvailable => _getString(
        pt: PortugueseStrings.decksStillAvailable,
        en: EnglishStrings.decksStillAvailable,
      );

  String get retryLoadingProgress => _getString(
        pt: PortugueseStrings.retryLoadingProgress,
        en: EnglishStrings.retryLoadingProgress,
      );

  String get continueWithoutProgress => _getString(
        pt: PortugueseStrings.continueWithoutProgress,
        en: EnglishStrings.continueWithoutProgress,
      );

  String get skipAndContinue => _getString(
        pt: PortugueseStrings.skipAndContinue,
        en: EnglishStrings.skipAndContinue,
      );

  // Language names
  String get portuguese => _getString(
        pt: PortugueseStrings.portuguese,
        en: EnglishStrings.portuguese,
      );

  String get english => _getString(
        pt: PortugueseStrings.english,
        en: EnglishStrings.english,
      );

  String get hungarian => _getString(
        pt: PortugueseStrings.hungarian,
        en: EnglishStrings.hungarian,
      );

  // Helper method to get string based on current language
  String _getString({required String pt, required String en}) {
    switch (language.code) {
      case 'pt':
        return pt;
      case 'en':
        return en;
      default:
        return en; // Fallback to English
    }
  }
}