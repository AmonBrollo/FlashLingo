import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/language.dart';
import 'ui_language_service.dart';

/// Provider for managing UI language state throughout the app
class UiLanguageProvider extends ChangeNotifier {
  String _currentLanguageCode = 'en';
  late AppLocalizations _localizations;

  UiLanguageProvider() {
    _localizations = AppLocalizations.of(_currentLanguageCode);
    _loadLanguage();
  }

  /// Get the current language code (pt or en)
  String get languageCode => _currentLanguageCode;

  /// Get the current Language object
  Language get language => AppLanguages.getLanguageOrDefault(_currentLanguageCode);

  /// Get the localizations for the current language
  AppLocalizations get loc => _localizations;

  /// Load the saved language preference
  Future<void> _loadLanguage() async {
    final savedLanguage = await UiLanguageService.getUiLanguage();
    if (savedLanguage != _currentLanguageCode) {
      _currentLanguageCode = savedLanguage;
      _localizations = AppLocalizations.of(_currentLanguageCode);
      notifyListeners();
    }
  }

  /// Change the UI language
  Future<void> setLanguage(String languageCode) async {
    if (languageCode == _currentLanguageCode) return;

    _currentLanguageCode = languageCode;
    _localizations = AppLocalizations.of(languageCode);
    await UiLanguageService.setUiLanguage(languageCode);
    notifyListeners();
  }

  /// Toggle between Portuguese and English
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguageCode == 'pt' ? 'en' : 'pt';
    await setLanguage(newLanguage);
  }

  /// Check if current language is Portuguese
  bool get isPortuguese => _currentLanguageCode == 'pt';

  /// Check if current language is English
  bool get isEnglish => _currentLanguageCode == 'en';
}