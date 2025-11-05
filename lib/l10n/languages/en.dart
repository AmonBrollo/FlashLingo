/// English translations
class EnglishStrings {
  // Navigation & Screens
  static const String selectTargetLanguage = 'Choose Target Language 🎯';
  static const String selectDeck = 'Select a Deck';
  static const String profile = 'Profile';
  static const String review = 'Review';
  static const String reviewProgress = '📊 Review Progress';
  
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
  
  // Status & Progress
  static const String limitReached = '⏳ Limit reached';
  static const String newCard = 'New';
  static const String dueCard = 'Due';
  static const String learningCard = 'Learning';
  static const String forgottenCards = 'Forgotten Cards';
  
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
  
  // Messages
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String noData = 'No data available';
  static const String tryAgain = 'Please try again';
  
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
  
  // Data Management
  static const String dataManagement = 'Data Management';
  static const String resetProgress = 'Reset Learning Progress';
  static const String resetAllData = 'Reset All Data';
  static const String clearAllImages = 'Clear All Images';
  static const String cleanupUnusedImages = 'Cleanup Unused Images';
  static const String storageUsage = 'Storage Usage';
  
  // Confirmation Messages
  static const String areYouSure = 'Are you sure?';
  static const String cannotBeUndone = 'This action cannot be undone.';
  static const String logoutConfirm = 'Are you sure you want to logout?';
  
  // Deck Selector
  static const String loadingProgress = 'Loading progress...';
  static const String couldNotLoadProgress = 'Could not load progress';
  static const String decksStillAvailable = 'Don\'t worry, your decks are still available!';
  static const String retryLoadingProgress = 'Retry Loading Progress';
  static const String continueWithoutProgress = 'Continue Without Progress Data';
  static const String skipAndContinue = 'Skip and continue';
  
  // Language specific
  static const String portuguese = 'Portuguese';
  static const String english = 'English';
  static const String hungarian = 'Hungarian';
}