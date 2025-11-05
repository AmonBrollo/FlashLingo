/// Portuguese translations
class PortugueseStrings {
  // Navigation & Screens
  static const String selectTargetLanguage = 'Escolha o idioma de destino 🎯';
  static const String selectDeck = 'Selecione um Deck';
  static const String profile = 'Perfil';
  static const String review = 'Revisar';
  static const String reviewProgress = '📊 Revisar Progresso';
  
  // Flashcards
  static const String addFlashcard = 'Adicionar Carta';
  static const String addFlashcardTitle = 'Adicionar Carta';
  static const String noImageYet = 'Nenhuma imagem ainda.\nToque ✏️ para adicionar.';
  static const String finishedDeck = '🎉 Você passou por todas as cartas!';
  static const String tapToFlip = 'Toque para virar';
  static const String swipeRight = 'Deslize para direita se souber';
  static const String swipeLeft = 'Deslize para esquerda se precisar praticar';
  
  // Input Labels
  static const String enterEnglishWord = 'Digite a palavra em Inglês';
  static const String enterPortugueseWord = 'Digite a palavra em Português';
  static const String enterHungarianWord = 'Digite a palavra em Húngaro';
  static const String enterWord = 'Digite a palavra';
  
  // Status & Progress
  static const String limitReached = '⏳ Limite atingido';
  static const String newCard = 'Novo';
  static const String dueCard = 'Vencido';
  static const String learningCard = 'Aprendendo';
  static const String forgottenCards = 'Cartas Esquecidas';
  
  // Actions
  static const String add = 'Adicionar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Excluir';
  static const String save = 'Salvar';
  static const String edit = 'Editar';
  static const String done = 'Concluído';
  static const String skip = 'Pular';
  static const String next = 'Próximo';
  static const String previous = 'Anterior';
  static const String finish = 'Concluir';
  static const String retry = 'Tentar Novamente';
  static const String logout = 'Sair';
  static const String login = 'Entrar';
  
  // Messages
  static const String loading = 'Carregando...';
  static const String error = 'Erro';
  static const String success = 'Sucesso';
  static const String noData = 'Nenhum dado disponível';
  static const String tryAgain = 'Por favor, tente novamente';
  
  // Time-based messages
  static String comeBackIn(int hours, int minutes) {
    return 'Volte em ${hours}h ${minutes}m';
  }
  
  static String reviewLevel(int level) {
    return 'Revisão - Nível $level';
  }
  
  static String cardsCount(int current, int total) {
    return '$current/$total cartas';
  }
  
  static String reviewCards(int count) {
    return 'Revisar $count cartas';
  }
  
  // Tutorial
  static const String viewTutorial = 'Ver Tutorial';
  static const String learnHowToUse = 'Aprenda a usar o FlashLango';
  static const String startTutorial = 'Iniciar Tutorial';
  static const String tutorialWillStart = 'O tutorial começará na tela de seleção de baralhos.\n\nVocê pode pular a qualquer momento tocando no botão "Pular".';
  
  // Profile
  static const String anonymousUser = 'Usuário Anônimo';
  static const String loggedIn = 'Conectado';
  static const String signInToSaveProgress = 'Entre para Salvar Progresso';
  static const String signOut = 'Sair';
  static const String emailVerified = 'Email Verificado';
  static const String emailNotVerified = 'Email Não Verificado';
  static const String resendEmail = 'Reenviar Email';
  static const String iVerified = 'Eu Verifiquei';
  
  // Data Management
  static const String dataManagement = 'Gerenciamento de Dados';
  static const String resetProgress = 'Resetar Progresso de Aprendizado';
  static const String resetAllData = 'Resetar Todos os Dados';
  static const String clearAllImages = 'Limpar Todas as Imagens';
  static const String cleanupUnusedImages = 'Limpar Imagens Não Utilizadas';
  static const String storageUsage = 'Uso de Armazenamento';
  
  // Confirmation Messages
  static const String areYouSure = 'Tem certeza?';
  static const String cannotBeUndone = 'Esta ação não pode ser desfeita.';
  static const String logoutConfirm = 'Tem certeza que deseja sair?';
  
  // Deck Selector
  static const String loadingProgress = 'Carregando progresso...';
  static const String couldNotLoadProgress = 'Não foi possível carregar o progresso';
  static const String decksStillAvailable = 'Não se preocupe, seus baralhos ainda estão disponíveis!';
  static const String retryLoadingProgress = 'Tentar Carregar Progresso Novamente';
  static const String continueWithoutProgress = 'Continuar Sem Dados de Progresso';
  static const String skipAndContinue = 'Pular e continuar';
  
  // Language specific
  static const String portuguese = 'Português';
  static const String english = 'Inglês';
  static const String hungarian = 'Húngaro';
}