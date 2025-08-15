class UiStrings {
  static String appTitle(String lang) {
    return lang == "portuguese" ? "Flashlingo" : "Flashlingo";
  }

  static String reviewTitle(String lang) {
    return lang == "portuguese" ? "Revisar Cartas" : "Review Flashcards";
  }

  static String addFlashcardTitle(String lang) {
    return lang == "portuguese" ? "Adicionar Carta" : "Add Flashcard";
  }

  static String addFlashcardButton(String lang) {
    return lang == "portuguese" ? "Adicionar" : "Add Flashcard";
  }

  static String noImageText(String lang) {
    return lang == "portuguese"
        ? "Nenhuma imagem ainda.\nToque ✏️ para adicionar."
        : "No image yet.\nTap ✏️ to add one.";
  }

  static String finishedDeckText(String lang) {
    return lang == "portuguese"
        ? "🎉 Você passou por todas as cartas!"
        : "🎉 You've gone through all the flashcards!";
  }

  static String addHungarianWord(String lang) {
    return lang == "portuguese"
        ? "Digite a palavra em Húngaro"
        : "Enter Hungarian word";
  }

  static String limitReachedMessage(String lang) {
    return lang == "portuguese" ? "⏳ Limite atingido" : "⏳ Limit reached";
  }

  static String timeLeftMessage(String lang, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return lang == "portuguese"
        ? "Volte em ${hours}h ${minutes}m"
        : "Come back in ${hours}h ${minutes}m";
  }
}
