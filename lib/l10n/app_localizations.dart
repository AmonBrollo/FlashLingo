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

  String get chooseBaseLanguage => _getString(
        pt: PortugueseStrings.chooseBaseLanguage,
        en: EnglishStrings.chooseBaseLanguage,
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

  String get email => _getString(
        pt: PortugueseStrings.email,
        en: EnglishStrings.email,
      );

  String get password => _getString(
        pt: PortugueseStrings.password,
        en: EnglishStrings.password,
      );

  String get confirmPassword => _getString(
        pt: PortugueseStrings.confirmPassword,
        en: EnglishStrings.confirmPassword,
      );

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

  String get dueNow => _getString(
        pt: PortugueseStrings.dueNow,
        en: EnglishStrings.dueNow,
      );

  String get complete => _getString(
        pt: PortugueseStrings.complete,
        en: EnglishStrings.complete,
      );

  String get cardsLeft => _getString(
        pt: PortugueseStrings.cardsLeft,
        en: EnglishStrings.cardsLeft,
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

  String get createAccount => _getString(
        pt: PortugueseStrings.createAccount,
        en: EnglishStrings.createAccount,
      );

  String get continueWithoutAccount => _getString(
        pt: PortugueseStrings.continueWithoutAccount,
        en: EnglishStrings.continueWithoutAccount,
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

  String get welcomeBack => _getString(
        pt: PortugueseStrings.welcomeBack,
        en: EnglishStrings.welcomeBack,
      );

  String get joinFlashLango => _getString(
        pt: PortugueseStrings.joinFlashLango,
        en: EnglishStrings.joinFlashLango,
      );

  String get startLearning => _getString(
        pt: PortugueseStrings.startLearning,
        en: EnglishStrings.startLearning,
      );

  // Auth
  String get forgotPassword => _getString(
        pt: PortugueseStrings.forgotPassword,
        en: EnglishStrings.forgotPassword,
      );

  String get resetPassword => _getString(
        pt: PortugueseStrings.resetPassword,
        en: EnglishStrings.resetPassword,
      );

  String get emailSent => _getString(
        pt: PortugueseStrings.emailSent,
        en: EnglishStrings.emailSent,
      );

  String get accountCreated => _getString(
        pt: PortugueseStrings.accountCreated,
        en: EnglishStrings.accountCreated,
      );

  String get continueToLogin => _getString(
        pt: PortugueseStrings.continueToLogin,
        en: EnglishStrings.continueToLogin,
      );

  // Validation Messages
  String get enterEmail => _getString(
        pt: PortugueseStrings.enterEmail,
        en: EnglishStrings.enterEmail,
      );

  String get enterValidEmail => _getString(
        pt: PortugueseStrings.enterValidEmail,
        en: EnglishStrings.enterValidEmail,
      );

  String get enterPassword => _getString(
        pt: PortugueseStrings.enterPassword,
        en: EnglishStrings.enterPassword,
      );

  String get passwordTooShort => _getString(
        pt: PortugueseStrings.passwordTooShort,
        en: EnglishStrings.passwordTooShort,
      );

  String get confirmYourPassword => _getString(
        pt: PortugueseStrings.confirmYourPassword,
        en: EnglishStrings.confirmYourPassword,
      );

  String get passwordsDoNotMatch => _getString(
        pt: PortugueseStrings.passwordsDoNotMatch,
        en: EnglishStrings.passwordsDoNotMatch,
      );

  String get pleaseEnterEmailFirst => _getString(
        pt: PortugueseStrings.pleaseEnterEmailFirst,
        en: EnglishStrings.pleaseEnterEmailFirst,
      );

  // Error Messages
  String get noAccountFound => _getString(
        pt: PortugueseStrings.noAccountFound,
        en: EnglishStrings.noAccountFound,
      );

  String get incorrectPassword => _getString(
        pt: PortugueseStrings.incorrectPassword,
        en: EnglishStrings.incorrectPassword,
      );

  String get invalidEmail => _getString(
        pt: PortugueseStrings.invalidEmail,
        en: EnglishStrings.invalidEmail,
      );

  String get tooManyRequests => _getString(
        pt: PortugueseStrings.tooManyRequests,
        en: EnglishStrings.tooManyRequests,
      );

  String get invalidCredential => _getString(
        pt: PortugueseStrings.invalidCredential,
        en: EnglishStrings.invalidCredential,
      );

  String get emailAlreadyInUse => _getString(
        pt: PortugueseStrings.emailAlreadyInUse,
        en: EnglishStrings.emailAlreadyInUse,
      );

  String get weakPassword => _getString(
        pt: PortugueseStrings.weakPassword,
        en: EnglishStrings.weakPassword,
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

  String levelName(int level) {
    return language.code == 'pt'
        ? PortugueseStrings.levelName(level)
        : EnglishStrings.levelName(level);
  }

  String levelDescription(int level) {
    return language.code == 'pt'
        ? PortugueseStrings.levelDescription(level)
        : EnglishStrings.levelDescription(level);
  }

  String cardsDue(int count) {
    return language.code == 'pt'
        ? PortugueseStrings.cardsDue(count)
        : EnglishStrings.cardsDue(count);
  }

  String cardsTotal(int count) {
    return language.code == 'pt'
        ? PortugueseStrings.cardsTotal(count)
        : EnglishStrings.cardsTotal(count);
  }

  String dueInDays(int days) {
    return language.code == 'pt'
        ? PortugueseStrings.dueInDays(days)
        : EnglishStrings.dueInDays(days);
  }

  String dueInHours(int hours) {
    return language.code == 'pt'
        ? PortugueseStrings.dueInHours(hours)
        : EnglishStrings.dueInHours(hours);
  }

  String dueInMinutes(int minutes) {
    return language.code == 'pt'
        ? PortugueseStrings.dueInMinutes(minutes)
        : EnglishStrings.dueInMinutes(minutes);
  }

  String availableIn(String time) {
    return language.code == 'pt'
        ? PortugueseStrings.availableIn(time)
        : EnglishStrings.availableIn(time);
  }

  String freeUpStorage(String sizeMB) {
    return language.code == 'pt'
        ? PortugueseStrings.freeUpStorage(sizeMB)
        : EnglishStrings.freeUpStorage(sizeMB);
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

  String get pleaseVerifyEmail => _getString(
        pt: PortugueseStrings.pleaseVerifyEmail,
        en: EnglishStrings.pleaseVerifyEmail,
      );

  String get signInToSync => _getString(
        pt: PortugueseStrings.signInToSync,
        en: EnglishStrings.signInToSync,
      );

  // Sync Status
  String get syncStatus => _getString(
        pt: PortugueseStrings.syncStatus,
        en: EnglishStrings.syncStatus,
      );

  String get syncNow => _getString(
        pt: PortugueseStrings.syncNow,
        en: EnglishStrings.syncNow,
      );

  String get syncing => _getString(
        pt: PortugueseStrings.syncing,
        en: EnglishStrings.syncing,
      );

  String get syncCompleted => _getString(
        pt: PortugueseStrings.syncCompleted,
        en: EnglishStrings.syncCompleted,
      );

  String get changesPending => _getString(
        pt: PortugueseStrings.changesPending,
        en: EnglishStrings.changesPending,
      );

  String get progressSyncsAutomatically => _getString(
        pt: PortugueseStrings.progressSyncsAutomatically,
        en: EnglishStrings.progressSyncsAutomatically,
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

  String get images => _getString(
        pt: PortugueseStrings.images,
        en: EnglishStrings.images,
      );

  String get files => _getString(
        pt: PortugueseStrings.files,
        en: EnglishStrings.files,
      );

  String get storageUsed => _getString(
        pt: PortugueseStrings.storageUsed,
        en: EnglishStrings.storageUsed,
      );

  String get cleanupCompleted => _getString(
        pt: PortugueseStrings.cleanupCompleted,
        en: EnglishStrings.cleanupCompleted,
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

  String get removeImage => _getString(
        pt: PortugueseStrings.removeImage,
        en: EnglishStrings.removeImage,
      );

  String get removeImageConfirm => _getString(
        pt: PortugueseStrings.removeImageConfirm,
        en: EnglishStrings.removeImageConfirm,
      );

  String get remove => _getString(
        pt: PortugueseStrings.remove,
        en: EnglishStrings.remove,
      );

  String get imageSavedSuccessfully => _getString(
        pt: PortugueseStrings.imageSavedSuccessfully,
        en: EnglishStrings.imageSavedSuccessfully,
      );

  String get failedToSaveImage => _getString(
        pt: PortugueseStrings.failedToSaveImage,
        en: EnglishStrings.failedToSaveImage,
      );

  String get imageRemoved => _getString(
        pt: PortugueseStrings.imageRemoved,
        en: EnglishStrings.imageRemoved,
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

  String get noCardsToReviewYet => _getString(
        pt: PortugueseStrings.noCardsToReviewYet,
        en: EnglishStrings.noCardsToReviewYet,
      );

  String get studyFlashcardsToSeeHere => _getString(
        pt: PortugueseStrings.studyFlashcardsToSeeHere,
        en: EnglishStrings.studyFlashcardsToSeeHere,
      );

  String get availableSoon => _getString(
        pt: PortugueseStrings.availableSoon,
        en: EnglishStrings.availableSoon,
      );

  String get noCards => _getString(
        pt: PortugueseStrings.noCards,
        en: EnglishStrings.noCards,
      );

  // Image Management
  String get selectImageSource => _getString(
        pt: PortugueseStrings.selectImageSource,
        en: EnglishStrings.selectImageSource,
      );

  String get camera => _getString(
        pt: PortugueseStrings.camera,
        en: EnglishStrings.camera,
      );

  String get gallery => _getString(
        pt: PortugueseStrings.gallery,
        en: EnglishStrings.gallery,
      );

  String get audioNotAvailable => _getString(
        pt: PortugueseStrings.audioNotAvailable,
        en: EnglishStrings.audioNotAvailable,
      );

  String get image => _getString(
        pt: PortugueseStrings.image,
        en: EnglishStrings.image,
      );

  // Review Actions
  String get forgot => _getString(
        pt: PortugueseStrings.forgot,
        en: EnglishStrings.forgot,
      );

  String get remember => _getString(
        pt: PortugueseStrings.remember,
        en: EnglishStrings.remember,
      );

  String get flip => _getString(
        pt: PortugueseStrings.flip,
        en: EnglishStrings.flip,
      );

  // Password Reset
  String get passwordResetLinkWillBeSent => _getString(
        pt: PortugueseStrings.passwordResetLinkWillBeSent,
        en: EnglishStrings.passwordResetLinkWillBeSent,
      );

  String get checkEmailInboxAndSpam => _getString(
        pt: PortugueseStrings.checkEmailInboxAndSpam,
        en: EnglishStrings.checkEmailInboxAndSpam,
      );

  String get accountCreatedSuccessfully => _getString(
        pt: PortugueseStrings.accountCreatedSuccessfully,
        en: EnglishStrings.accountCreatedSuccessfully,
      );

  String get verificationEmailSentTo => _getString(
        pt: PortugueseStrings.verificationEmailSentTo,
        en: EnglishStrings.verificationEmailSentTo,
      );

  String get pleaseCheckInboxToVerify => _getString(
        pt: PortugueseStrings.pleaseCheckInboxToVerify,
        en: EnglishStrings.pleaseCheckInboxToVerify,
      );

  String get canStartUsingAppNow => _getString(
        pt: PortugueseStrings.canStartUsingAppNow,
        en: EnglishStrings.canStartUsingAppNow,
      );

  String get verificationEmailSent => _getString(
        pt: PortugueseStrings.verificationEmailSent,
        en: EnglishStrings.verificationEmailSent,
      );

  String get alreadyHaveAccountForgotPassword => _getString(
        pt: PortugueseStrings.alreadyHaveAccountForgotPassword,
        en: EnglishStrings.alreadyHaveAccountForgotPassword,
      );

  String get selectDeckMenu => _getString(
        pt: PortugueseStrings.selectDeckMenu,
        en: EnglishStrings.selectDeckMenu,
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

  // App Info
  String get flashLango => _getString(
        pt: PortugueseStrings.flashLango,
        en: EnglishStrings.flashLango,
      );

  String get somethingWentWrong => _getString(
        pt: PortugueseStrings.somethingWentWrong,
        en: EnglishStrings.somethingWentWrong,
      );

  String get pleaseRestartApp => _getString(
        pt: PortugueseStrings.pleaseRestartApp,
        en: EnglishStrings.pleaseRestartApp,
      );

  String get ok => _getString(
        pt: PortugueseStrings.ok,
        en: EnglishStrings.ok,
      );

  String get or => _getString(
        pt: PortugueseStrings.or,
        en: EnglishStrings.or,
      );

  // App Router specific
  String get checkingAuthentication => _getString(
        pt: PortugueseStrings.checkingAuthentication,
        en: EnglishStrings.checkingAuthentication,
      );

  String get refreshingData => _getString(
        pt: PortugueseStrings.refreshingData,
        en: EnglishStrings.refreshingData,
      );

  String get loadingDecks => _getString(
        pt: PortugueseStrings.loadingDecks,
        en: EnglishStrings.loadingDecks,
      );

  String get noDeckFound => _getString(
        pt: PortugueseStrings.noDeckFound,
        en: EnglishStrings.noDeckFound,
      );

  String get checkInstallation => _getString(
        pt: PortugueseStrings.checkInstallation,
        en: EnglishStrings.checkInstallation,
      );

  String get usingOfflineData => _getString(
        pt: PortugueseStrings.usingOfflineData,
        en: EnglishStrings.usingOfflineData,
      );

  String get unableToLoad => _getString(
        pt: PortugueseStrings.unableToLoad,
        en: EnglishStrings.unableToLoad,
      );

  String get havingTroubleLoading => _getString(
        pt: PortugueseStrings.havingTroubleLoading,
        en: EnglishStrings.havingTroubleLoading,
      );

  String get resetSetup => _getString(
        pt: PortugueseStrings.resetSetup,
        en: EnglishStrings.resetSetup,
      );

  String get connectionIssue => _getString(
        pt: PortugueseStrings.connectionIssue,
        en: EnglishStrings.connectionIssue,
      );

  String get checkInternetConnection => _getString(
        pt: PortugueseStrings.checkInternetConnection,
        en: EnglishStrings.checkInternetConnection,
      );

  String get skipToSetup => _getString(
        pt: PortugueseStrings.skipToSetup,
        en: EnglishStrings.skipToSetup,
      );

  String get takesJustMoment => _getString(
        pt: PortugueseStrings.takesJustMoment,
        en: EnglishStrings.takesJustMoment,
      );

  String get initializing => _getString(
        pt: PortugueseStrings.initializing,
        en: EnglishStrings.initializing,
      );

  String get initializationError => _getString(
        pt: PortugueseStrings.initializationError,
        en: EnglishStrings.initializationError,
      );

  String get authenticationError => _getString(
        pt: PortugueseStrings.authenticationError,
        en: EnglishStrings.authenticationError,
      );

  String get continueText => _getString(
        pt: PortugueseStrings.continueText,
        en: EnglishStrings.continueText,
      );

  // NEW: App Router Error Messages
  String get connectionTimeout => _getString(
        pt: PortugueseStrings.connectionTimeout,
        en: EnglishStrings.connectionTimeout,
      );

  String get networkError => _getString(
        pt: PortugueseStrings.networkError,
        en: EnglishStrings.networkError,
      );

  String get permissionDenied => _getString(
        pt: PortugueseStrings.permissionDenied,
        en: EnglishStrings.permissionDenied,
      );

  String get unexpectedError => _getString(
        pt: PortugueseStrings.unexpectedError,
        en: EnglishStrings.unexpectedError,
      );

  String get errorLoadingDecks => _getString(
        pt: PortugueseStrings.errorLoadingDecks,
        en: EnglishStrings.errorLoadingDecks,
      );

  // Deck Selector specific
  String get completeCheckmark => _getString(
        pt: PortugueseStrings.completeCheckmark,
        en: EnglishStrings.completeCheckmark,
      );

  // Flashcard Screen specific
  String get left => _getString(
        pt: PortugueseStrings.left,
        en: EnglishStrings.left,
      );

  String get audioNotAvailableError => _getString(
        pt: PortugueseStrings.audioNotAvailableError,
        en: EnglishStrings.audioNotAvailableError,
      );

  // Convenience properties
  String get languageCode => language.code;
  bool get isPortuguese => language.code == 'pt';
  bool get isEnglish => language.code == 'en';

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