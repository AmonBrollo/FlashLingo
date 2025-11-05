import '../l10n/app_localizations.dart';

/// DEPRECATED: Use AppLocalizations instead
/// This class is kept for backward compatibility during migration
/// 
/// Migration guide:
/// OLD: UiStrings.selectDeck(baseLanguage)
/// NEW: AppLocalizations.of(baseLanguage).selectDeck
class UiStrings {
  static String selectTargetLanguage(String lang) {
    return AppLocalizations.of(lang).selectTargetLanguage;
  }

  static String selectDeck(String lang) {
    return AppLocalizations.of(lang).selectDeck;
  }

  static String reviewTitle(String lang) {
    return AppLocalizations.of(lang).reviewProgress;
  }

  static String addFlashcardTitle(String lang) {
    return AppLocalizations.of(lang).addFlashcardTitle;
  }

  static String addFlashcardButton(String lang) {
    return AppLocalizations.of(lang).addFlashcard;
  }

  static String noImageText(String lang) {
    return AppLocalizations.of(lang).noImageYet;
  }

  static String finishedDeckText(String lang) {
    return AppLocalizations.of(lang).finishedDeck;
  }

  static String baseWordLabel(String lang) {
    return AppLocalizations.of(lang).getInputLabel(lang);
  }

  static String addHungarianWord(String lang) {
    return AppLocalizations.of(lang).enterHungarianWord;
  }

  static String limitReachedMessage(String lang) {
    return AppLocalizations.of(lang).limitReached;
  }

  static String timeLeftMessage(String lang, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return AppLocalizations.of(lang).comeBackIn(hours, minutes);
  }

  static String reviewStatusLevel(String lang, int level) {
    return AppLocalizations.of(lang).reviewLevel(level);
  }

  static String newCardStatus(String lang) {
    return AppLocalizations.of(lang).newCard;
  }
}