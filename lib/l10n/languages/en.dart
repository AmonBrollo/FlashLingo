/// English translations
class EnglishStrings {
  // Navigation & Screens
  static const String selectTargetLanguage = 'Choose Target Language 🎯';
  static const String selectDeck = 'Select a Deck';
  static const String profile = 'Profile';
  static const String review = 'Review';
  static const String reviewProgress = '📊 Review Progress';
  static const String chooseBaseLanguage = 'Choose Base Language';
  
  // Flashcards
  static const String addFlashcard = 'Add Flashcard';
  static const String addFlashcardTitle = 'Add Flashcard';
  static const String noImageYet = 'No image yet.\nTap ✏️ to add one.';
  static const String finishedDeck = '🎉 You\'ve gone through all the flashcards!';
  static const String tapToFlip = 'Tap to flip';
  static const String swipeRight = 'Swipe right if you know it';
  static const String swipeLeft = 'Swipe left if you need practice';
  
  // Input Labels
  static const String enterEnglishWord = 'Enter English word';
  static const String enterPortugueseWord = 'Enter Portuguese word';
  static const String enterHungarianWord = 'Enter Hungarian word';
  static const String enterWord = 'Enter word';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  
  // Status & Progress
  static const String limitReached = '⏳ Limit reached';
  static const String newCard = 'New';
  static const String dueCard = 'Due';
  static const String learningCard = 'Learning';
  static const String forgottenCards = 'Forgotten Cards';
  static const String dueNow = 'Due now';
  static const String noDueCards = 'No due cards';
  static const String complete = 'Complete';
  static const String cardsLeft = 'cards left';
  
  // Actions
  static const String add = 'Add';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String finish = 'Finish';
  static const String retry = 'Retry';
  static const String logout = 'Logout';
  static const String login = 'Login';
  static const String createAccount = 'Create Account';
  static const String register = 'Register';
  static const String continueWithoutAccount = 'Continue without account';
  static const String sendResetEmail = 'Send Reset Email';
  static const String resendVerificationEmail = 'Resend Verification Email';
  
  // Messages
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String noData = 'No data available';
  static const String tryAgain = 'Try Again';
  static const String welcomeBack = 'Welcome back!';
  static const String startLearning = 'Start learning languages today';
  static const String joinFlashLango = 'Join FlashLango';
  
  // Auth & Account
  static const String forgotPassword = 'Forgot password?';
  static const String resetPassword = 'Reset Password';
  static const String passwordResetFailed = 'Password Reset Failed';
  static const String emailSent = 'Email Sent!';
  static const String accountCreated = 'Account Created!';
  static const String continueToLogin = 'Continue to Login';
  
  // Validation Messages
  static const String enterEmail = 'Enter your email';
  static const String enterValidEmail = 'Enter a valid email';
  static const String enterPassword = 'Enter your password';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String confirmYourPassword = 'Confirm your password';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String pleaseEnterEmailFirst = 'Please enter your email address first';
  
  // Error Messages
  static const String loginFailed = 'Login failed. Please try again.';
  static const String registrationFailed = 'Registration failed';
  static const String noAccountFound = 'No account found with this email.';
  static const String incorrectPassword = 'Incorrect password.';
  static const String invalidEmail = 'Invalid email address.';
  static const String accountDisabled = 'This account has been disabled.';
  static const String tooManyRequests = 'Too many requests. Please try again later.';
  static const String invalidCredential = 'Invalid email or password.';
  static const String emailAlreadyInUse = 'An account already exists with this email.';
  static const String weakPassword = 'Password is too weak. Use at least 6 characters.';
  static const String anonymousSignInFailed = 'Anonymous sign-in failed';
  static const String errorSendingResetEmail = 'Error sending reset email';
  
  // Time-based messages
  static String comeBackIn(int hours, int minutes) {
    return 'Come back in ${hours}h ${minutes}m';
  }
  
  static String reviewLevel(int level) {
    return 'Review - Level $level';
  }
  
  static String cardsCount(int current, int total) {
    return '$current/$total cards';
  }
  
  static String reviewCards(int count) {
    return 'Review $count cards';
  }
  
  static String dueInDays(int days) {
    return 'Due in ${days}d';
  }
  
  static String dueInHours(int hours) {
    return 'Due in ${hours}h';
  }
  
  static String dueInMinutes(int minutes) {
    return 'Due in ${minutes}m';
  }
  
  static String availableIn(String time) {
    return 'Available in $time';
  }
  
  static String cardsDue(int count) {
    return '$count cards due';
  }
  
  static String cardsTotal(int count) {
    return '$count cards';
  }
  
  // Tutorial
  static const String viewTutorial = 'View Tutorial';
  static const String learnHowToUse = 'Learn how to use FlashLango';
  static const String startTutorial = 'Start Tutorial';
  static const String tutorialWillStart = 'The tutorial will start from the deck selector screen.\n\nYou can skip it anytime by tapping the "Skip" button.';
  
  // Profile
  static const String anonymousUser = 'Anonymous User';
  static const String loggedIn = 'Logged In';
  static const String signInToSaveProgress = 'Sign In to Save Progress';
  static const String signOut = 'Sign Out';
  static const String emailVerified = 'Email Verified';
  static const String emailNotVerified = 'Email Not Verified';
  static const String resendEmail = 'Resend Email';
  static const String iVerified = 'I Verified';
  static const String pleaseVerifyEmail = 'Please verify your email address to secure your account.';
  static const String emailVerifiedSuccessfully = 'Email verified successfully! 🎉';
  static const String emailNotVerifiedYet = 'Email not verified yet. Please check your inbox.';
  static const String errorCheckingVerification = 'Error checking verification';
  static const String signInToSync = 'Sign in to sync your progress across devices';
  
  // Sync Status
  static const String syncStatus = 'Sync Status';
  static const String syncNow = 'Sync Now';
  static const String syncing = 'Syncing...';
  static const String syncCompleted = 'Sync completed successfully';
  static const String syncFailed = 'Sync failed';
  static const String syncError = 'Sync error';
  static const String changesPending = 'Changes pending';
  static const String progressSyncsAutomatically = 'Your progress syncs automatically across devices';
  
  // Data Management
  static const String dataManagement = 'Data Management';
  static const String resetProgress = 'Reset Learning Progress';
  static const String resetAllData = 'Reset All Data';
  static const String clearAllImages = 'Clear All Images';
  static const String cleanupUnusedImages = 'Cleanup Unused Images';
  static const String storageUsage = 'Storage Usage';
  static const String images = 'Images';
  static const String files = 'files';
  static const String storageUsed = 'Storage used';
  static const String cleanupCompleted = 'Cleanup completed';
  static const String errorDuringCleanup = 'Error during cleanup';
  
  // Confirmation Messages
  static const String areYouSure = 'Are you sure?';
  static const String cannotBeUndone = 'This action cannot be undone.';
  static const String logoutConfirm = 'Are you sure you want to logout?';
  static const String removeImage = 'Remove Image';
  static const String removeImageConfirm = 'Are you sure you want to remove this image?';
  static const String remove = 'Remove';
  static const String thisWillPermanentlyDelete = 'This will permanently delete ALL your data:';
  static const String learningProgressAndStats = '• Learning progress and statistics';
  static const String languageAndDeckPrefs = '• Language and deck preferences';
  static const String allFlashcardImages = '• All flashcard images';
  static const String accountPreferences = '• Account preferences';
  static const String thisCannotBeUndone = '⚠️ THIS CANNOT BE UNDONE';
  static const String deleteAllData = 'DELETE ALL DATA';
  static const String allDataReset = 'All data has been reset';
  static const String progressResetSuccessfully = 'Progress reset successfully';
  static const String errorResettingProgress = 'Error resetting progress';
  static const String errorResettingAllData = 'Error resetting all data';
  static const String imageSavedSuccessfully = 'Image saved successfully';
  static const String failedToSaveImage = 'Failed to save image';
  static const String imageRemoved = 'Image removed';
  static const String imagesCleared = 'All images cleared successfully';
  static const String errorClearingImages = 'Error clearing images';
  
  // Deck Selector
  static const String loadingProgress = 'Loading progress...';
  static const String couldNotLoadProgress = 'Could not load progress';
  static const String decksStillAvailable = 'Don\'t worry, your decks are still available!';
  static const String retryLoadingProgress = 'Retry Loading Progress';
  static const String continueWithoutProgress = 'Continue Without Progress Data';
  static const String skipAndContinue = 'Skip and continue';
  static const String noCardsToReviewYet = 'No cards to review yet';
  static const String studyFlashcardsToSeeHere = 'Study some flashcards to see them here';
  static const String loadingReviewData = 'Loading review data...';
  static const String errorLoadingDecks = 'Error loading decks';
  
  // Level Names & Descriptions
  static String levelName(int level) {
    return 'Level $level';
  }
  
  static String levelDescription(int level) {
    switch (level) {
      case 1:
        return 'New/Difficult (1 day)';
      case 2:
        return 'Learning (2 days)';
      case 3:
        return 'Familiar (4 days)';
      case 4:
        return 'Known (1 week)';
      case 5:
        return 'Mastered (2 weeks)';
      default:
        return 'Level $level';
    }
  }
  
  static const String newDifficult = 'New/Difficult';
  static const String learning = 'Learning';
  static const String familiar = 'Familiar';
  static const String known = 'Known';
  static const String mastered = 'Mastered';
  static const String noCards = 'No cards';
  static const String availableSoon = 'Available soon';
  
  // Image Management
  static const String selectImageSource = 'Select Image Source';
  static const String camera = 'Camera';
  static const String gallery = 'Gallery';
  static const String audioNotAvailable = 'Audio not available';
  static const String image = 'Image';
  
  // Review Actions
  static const String forgot = 'Forgot';
  static const String remember = 'Remember';
  static const String flip = 'Flip';
  
  // Password Reset Dialog
  static const String passwordResetLinkWillBeSent = 'A password reset link will be sent to:';
  static const String checkEmailInboxAndSpam = 'Check your email inbox and spam folder.';
  static const String passwordResetEmailSent = 'Password reset email sent to:';
  static const String checkInboxAndSpam = 'Check your inbox and spam folder. The link will expire in 1 hour.';
  
  // Registration Messages
  static const String accountCreatedSuccessfully = 'Your account has been created successfully.';
  static const String verificationEmailSentTo = 'We\'ve sent a verification email to:';
  static const String pleaseCheckInboxToVerify = 'Please check your inbox and spam folder to verify your email address.';
  static const String canStartUsingAppNow = 'You can start using the app now. Verification is optional but recommended.';
  static const String verificationEmailSent = 'Verification email sent! Check your inbox.';
  static const String tooManyEmailRequests = 'Too many requests. Please try again later.';
  static const String failedToSendVerificationEmail = 'Failed to send verification email';
  static const String alreadyHaveAccountForgotPassword = 'Already have an account but forgot password?';
  static const String accountCreatedButEmailFailed = 'Account created! However, verification email could not be sent. You can resend it from your profile.';
  
  // Menu Items
  static const String selectDeckMenu = 'Select Deck';
  
  // Storage Info
  static String freeUpStorage(String sizeMB) {
    return 'This will free up $sizeMB MB of storage space.';
  }
  
  // Language specific
  static const String portuguese = 'Portuguese';
  static const String english = 'English';
  static const String hungarian = 'Hungarian';
  
  // App Info
  static const String flashLango = 'FlashLango';
  static const String somethingWentWrong = 'Something went wrong';
  static const String pleaseRestartApp = 'Please restart the app';
  
  // Additional Dialog Messages
  static const String ok = 'OK';
  static const String or = 'OR';
  
  // App Router specific
  static const String checkingAuthentication = 'Checking authentication...';
  static const String refreshingData = 'Refreshing data...';
  static const String loadingDecks = 'Loading flashcard decks...';
  static const String noDeckFound = 'No flashcard decks found';
  static const String checkInstallation = 'Please check your installation';
  static const String usingOfflineData = 'Using offline data...';
  static const String unableToLoad = 'Unable to Load';
  static const String havingTroubleLoading = 'We\'re having trouble loading your data. What would you like to do?';
  static const String resetSetup = 'Reset Setup';
  static const String connectionIssue = 'Connection Issue';
  static const String checkInternetConnection = 'Please check your internet connection.';
  static const String skipToSetup = 'Skip to Setup';
  static const String takesJustMoment = 'This usually takes just a moment...';
  static const String initializing = 'Initializing...';
  static const String initializationError = 'Initialization Error';
  static const String authenticationError = 'Authentication Error';
  static const String continueText = 'Continue';
  
  // NEW: App Router Error Messages
  static const String connectionTimeout = 'Connection timeout. Please check your internet.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String permissionDenied = 'Permission denied. Please check your settings.';
  static const String unexpectedError = 'An unexpected error occurred.';
}