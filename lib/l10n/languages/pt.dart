/// Portuguese translations
class PortugueseStrings {
  // Navigation & Screens
  static const String selectTargetLanguage = 'Escolha o idioma de destino 🎯';
  static const String selectDeck = 'Selecione um Deck';
  static const String profile = 'Perfil';
  static const String review = 'Revisar';
  static const String reviewProgress = '📊 Revisar Progresso';
  static const String chooseBaseLanguage = 'Escolha o Idioma Base';
  
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
  static const String email = 'Email';
  static const String password = 'Senha';
  static const String confirmPassword = 'Confirmar Senha';
  
  // Status & Progress
  static const String limitReached = '⏳ Limite atingido';
  static const String newCard = 'Novo';
  static const String dueCard = 'Vencido';
  static const String learningCard = 'Aprendendo';
  static const String forgottenCards = 'Cartas Esquecidas';
  static const String dueNow = 'Vencido agora';
  static const String noDueCards = 'Sem cartas vencidas';
  static const String complete = 'Completo';
  static const String cardsLeft = 'cartas restantes';
  
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
  static const String createAccount = 'Criar Conta';
  static const String register = 'Registrar';
  static const String continueWithoutAccount = 'Continuar sem conta';
  static const String sendResetEmail = 'Enviar Email de Redefinição';
  static const String resendVerificationEmail = 'Reenviar Email de Verificação';
  
  // Messages
  static const String loading = 'Carregando...';
  static const String error = 'Erro';
  static const String success = 'Sucesso';
  static const String noData = 'Nenhum dado disponível';
  static const String tryAgain = 'Tentar Novamente';
  static const String welcomeBack = 'Bem-vindo de volta!';
  static const String startLearning = 'Comece a aprender idiomas hoje';
  static const String joinFlashLango = 'Junte-se ao FlashLango';
  
  // Auth & Account
  static const String forgotPassword = 'Esqueceu a senha?';
  static const String resetPassword = 'Redefinir Senha';
  static const String passwordResetFailed = 'Falha ao Redefinir Senha';
  static const String emailSent = 'Email Enviado!';
  static const String accountCreated = 'Conta Criada!';
  static const String continueToLogin = 'Continuar para Login';
  
  // Validation Messages
  static const String enterEmail = 'Digite seu email';
  static const String enterValidEmail = 'Digite um email válido';
  static const String enterPassword = 'Digite sua senha';
  static const String passwordTooShort = 'A senha deve ter pelo menos 6 caracteres';
  static const String confirmYourPassword = 'Confirme sua senha';
  static const String passwordsDoNotMatch = 'As senhas não coincidem';
  static const String pleaseEnterEmailFirst = 'Por favor, insira seu endereço de email primeiro';
  
  // Error Messages
  static const String loginFailed = 'Falha no login. Por favor, tente novamente.';
  static const String registrationFailed = 'Falha no registro';
  static const String noAccountFound = 'Nenhuma conta encontrada com este email.';
  static const String incorrectPassword = 'Senha incorreta.';
  static const String invalidEmail = 'Endereço de email inválido.';
  static const String accountDisabled = 'Esta conta foi desativada.';
  static const String tooManyRequests = 'Muitas solicitações. Por favor, tente novamente mais tarde.';
  static const String invalidCredential = 'Email ou senha inválidos.';
  static const String emailAlreadyInUse = 'Já existe uma conta com este email.';
  static const String weakPassword = 'Senha muito fraca. Use pelo menos 6 caracteres.';
  static const String anonymousSignInFailed = 'Falha no login anônimo';
  static const String errorSendingResetEmail = 'Erro ao enviar email de redefinição';
  
  // Time-based messages
  static String comeBackIn(int hours, int minutes) {
    return 'Volte em ${hours}h ${minutes}m';
  }
  
  static String reviewLevel(int level) {
    return 'Revisar - Nível $level';
  }
  
  static String cardsCount(int current, int total) {
    return '$current/$total cartas';
  }
  
  static String reviewCards(int count) {
    return 'Revisar $count cartas';
  }
  
  static String dueInDays(int days) {
    return 'Vence em ${days}d';
  }
  
  static String dueInHours(int hours) {
    return 'Vence em ${hours}h';
  }
  
  static String dueInMinutes(int minutes) {
    return 'Vence em ${minutes}m';
  }
  
  static String availableIn(String time) {
    return 'Disponível em $time';
  }
  
  static String cardsDue(int count) {
    return '$count cartas vencidas';
  }
  
  static String cardsTotal(int count) {
    return '$count cartas';
  }
  
  // Tutorial
  static const String viewTutorial = 'Ver Tutorial';
  static const String learnHowToUse = 'Aprenda a usar o FlashLingo';
  static const String startTutorial = 'Iniciar Tutorial';
  static const String tutorialWillStart = 'O tutorial começará na tela de seleção de deck.\n\nVocê pode pulá-lo a qualquer momento tocando no botão "Pular".';
  
  // Profile
  static const String anonymousUser = 'Usuário Anônimo';
  static const String loggedIn = 'Conectado';
  static const String signInToSaveProgress = 'Faça login para salvar o progresso';
  static const String signOut = 'Sair';
  static const String emailVerified = 'Email Verificado';
  static const String emailNotVerified = 'Email Não Verificado';
  static const String resendEmail = 'Reenviar Email';
  static const String iVerified = 'Já Verifiquei';
  static const String pleaseVerifyEmail = 'Por favor, verifique seu endereço de email para proteger sua conta.';
  static const String emailVerifiedSuccessfully = 'Email verificado com sucesso! 🎉';
  static const String emailNotVerifiedYet = 'Email ainda não verificado. Por favor, verifique sua caixa de entrada.';
  static const String errorCheckingVerification = 'Erro ao verificar confirmação';
  static const String signInToSync = 'Faça login para sincronizar seu progresso entre dispositivos';
  
  // Sync Status
  static const String syncStatus = 'Status de Sincronização';
  static const String syncNow = 'Sincronizar Agora';
  static const String syncing = 'Sincronizando...';
  static const String syncCompleted = 'Sincronização concluída com sucesso';
  static const String syncFailed = 'Falha na sincronização';
  static const String syncError = 'Erro de sincronização';
  static const String changesPending = 'Alterações pendentes';
  static const String progressSyncsAutomatically = 'Seu progresso sincroniza automaticamente entre dispositivos';
  
  // Data Management
  static const String dataManagement = 'Gerenciamento de Dados';
  static const String resetProgress = 'Redefinir Progresso de Aprendizado';
  static const String resetAllData = 'Redefinir Todos os Dados';
  static const String clearAllImages = 'Limpar Todas as Imagens';
  static const String cleanupUnusedImages = 'Limpar Imagens Não Usadas';
  static const String storageUsage = 'Uso de Armazenamento';
  static const String images = 'Imagens';
  static const String files = 'arquivos';
  static const String storageUsed = 'Armazenamento usado';
  static const String cleanupCompleted = 'Limpeza concluída';
  static const String errorDuringCleanup = 'Erro durante a limpeza';
  
  // Confirmation Messages
  static const String areYouSure = 'Tem certeza?';
  static const String cannotBeUndone = 'Esta ação não pode ser desfeita.';
  static const String logoutConfirm = 'Tem certeza que deseja sair?';
  static const String removeImage = 'Remover Imagem';
  static const String removeImageConfirm = 'Tem certeza que deseja remover esta imagem?';
  static const String remove = 'Remover';
  static const String thisWillPermanentlyDelete = 'Isso excluirá permanentemente TODOS os seus dados:';
  static const String learningProgressAndStats = '• Progresso e estatísticas de aprendizado';
  static const String languageAndDeckPrefs = '• Preferências de idioma e deck';
  static const String allFlashcardImages = '• Todas as imagens dos flashcards';
  static const String accountPreferences = '• Preferências da conta';
  static const String thisCannotBeUndone = '⚠️ ISSO NÃO PODE SER DESFEITO';
  static const String deleteAllData = 'EXCLUIR TODOS OS DADOS';
  static const String allDataReset = 'Todos os dados foram redefinidos';
  static const String progressResetSuccessfully = 'Progresso redefinido com sucesso';
  static const String errorResettingProgress = 'Erro ao redefinir o progresso';
  static const String errorResettingAllData = 'Erro ao redefinir todos os dados';
  static const String imageSavedSuccessfully = 'Imagem salva com sucesso';
  static const String failedToSaveImage = 'Falha ao salvar imagem';
  static const String imageRemoved = 'Imagem removida';
  static const String imagesCleared = 'Todas as imagens foram limpas com sucesso';
  static const String errorClearingImages = 'Erro ao limpar imagens';
  
  // Deck Selector
  static const String loadingProgress = 'Carregando progresso...';
  static const String couldNotLoadProgress = 'Não foi possível carregar o progresso';
  static const String decksStillAvailable = 'Não se preocupe, seus decks ainda estão disponíveis!';
  static const String retryLoadingProgress = 'Tentar Carregar Progresso Novamente';
  static const String continueWithoutProgress = 'Continuar Sem Dados de Progresso';
  static const String skipAndContinue = 'Pular e continuar';
  static const String noCardsToReviewYet = 'Sem cartas para revisar ainda';
  static const String studyFlashcardsToSeeHere = 'Estude alguns flashcards para vê-los aqui';
  static const String loadingReviewData = 'Carregando dados de revisão...';
  static const String errorLoadingDecks = 'Erro ao carregar decks';
  
  // Level Names & Descriptions
  static String levelName(int level) {
    switch (level) {
      case 1:
        return 'Novo';
      case 2:
        return 'Aprendendo';
      case 3:
        return 'Familiar';
      case 4:
        return 'Conhecido';
      case 5:
        return 'Dominado';
      default:
        return 'Nível $level';
    }
  }
  
  static String levelDescription(int level) {
    switch (level) {
      case 1:
        return 'Novo/Difícil (1 dia)';
      case 2:
        return 'Aprendendo (2 dias)';
      case 3:
        return 'Familiar (4 dias)';
      case 4:
        return 'Conhecido (1 semana)';
      case 5:
        return 'Dominado (2 semanas)';
      default:
        return 'Nível $level';
    }
  }
  
  static String boxLabel(int level) {
    if (level == -1) return 'Caixa ✕';
    return 'Caixa $level';
  }

  static const String newDifficult = 'Novo/Difícil';
  static const String learning = 'Aprendendo';
  static const String familiar = 'Familiar';
  static const String known = 'Conhecido';
  static const String mastered = 'Dominado';
  static const String noCards = 'Sem cartas';
  static const String availableSoon = 'Em breve';
  
  // Image Management
  static const String selectImageSource = 'Selecionar Fonte de Imagem';
  static const String camera = 'Câmera';
  static const String gallery = 'Galeria';
  static const String audioNotAvailable = 'Áudio não disponível';
  static const String image = 'Imagem';
  
  // Review Actions
  static const String forgot = 'Esqueci';
  static const String remember = 'Lembrei';
  static const String flip = 'Virar';
  static const String flipCardFirst = 'Por favor, vire a carta primeiro para ver a tradução';
  
  // Password Reset Dialog
  static const String passwordResetLinkWillBeSent = 'Um link de redefinição de senha será enviado para:';
  static const String checkEmailInboxAndSpam = 'Verifique sua caixa de entrada e a pasta de spam.';
  static const String passwordResetEmailSent = 'Email de redefinição de senha enviado para:';
  static const String checkInboxAndSpam = 'Verifique sua caixa de entrada e spam. O link expirará em 1 hora.';
  
  // Registration Messages
  static const String accountCreatedSuccessfully = 'Sua conta foi criada com sucesso.';
  static const String verificationEmailSentTo = 'Enviamos um email de verificação para:';
  static const String pleaseCheckInboxToVerify = 'Por favor, verifique sua caixa de entrada e spam para verificar seu endereço de email.';
  static const String canStartUsingAppNow = 'Você já pode começar a usar o aplicativo. A verificação é opcional, mas recomendada.';
  static const String verificationEmailSent = 'Email de verificação enviado! Verifique sua caixa de entrada.';
  static const String tooManyEmailRequests = 'Muitas solicitações. Por favor, tente novamente mais tarde.';
  static const String failedToSendVerificationEmail = 'Falha ao enviar email de verificação';
  static const String alreadyHaveAccountForgotPassword = 'Já tem uma conta mas esqueceu a senha?';
  static const String accountCreatedButEmailFailed = 'Conta criada! No entanto, o email de verificação não pôde ser enviado. Você pode reenviar pelo seu perfil.';
  
  // Menu Items
  static const String selectDeckMenu = 'Selecionar Deck';
  
  // Storage Info
  static String freeUpStorage(String sizeMB) {
    return 'Isso liberará $sizeMB MB de espaço de armazenamento.';
  }
  
  // Language specific
  static const String portuguese = 'Português';
  static const String english = 'Inglês';
  static const String hungarian = 'Húngaro';
  
  // App Info
  static const String flashLango = 'FlashLingo';
  static const String somethingWentWrong = 'Algo deu errado';
  static const String pleaseRestartApp = 'Por favor, reinicie o aplicativo';
  
  // Additional Dialog Messages
  static const String ok = 'OK';
  static const String or = 'OU';
  
  // App Router specific
  static const String checkingAuthentication = 'Verificando autenticação...';
  static const String refreshingData = 'Atualizando dados...';
  static const String loadingDecks = 'Carregando decks de flashcards...';
  static const String noDeckFound = 'Nenhum deck de flashcard encontrado';
  static const String checkInstallation = 'Por favor, verifique sua instalação';
  static const String usingOfflineData = 'Usando dados offline...';
  static const String unableToLoad = 'Não foi possível carregar';
  static const String havingTroubleLoading = 'Estamos com problemas para carregar seus dados. O que você gostaria de fazer?';
  static const String resetSetup = 'Redefinir Configuração';
  static const String connectionIssue = 'Problema de Conexão';
  static const String checkInternetConnection = 'Por favor, verifique sua conexão com a internet.';
  static const String skipToSetup = 'Ir para Configuração';
  static const String takesJustMoment = 'Isso geralmente leva apenas um momento...';
  static const String initializing = 'Inicializando...';
  static const String initializationError = 'Erro de Inicialização';
  static const String authenticationError = 'Erro de Autenticação';
  static const String continueText = 'Continuar';
  
  // NEW: App Router Error Messages
  static const String connectionTimeout = 'Tempo esgotado. Verifique sua internet.';
  static const String networkError = 'Erro de rede. Verifique sua conexão.';
  static const String permissionDenied = 'Permissão negada. Verifique suas configurações.';
  static const String unexpectedError = 'Ocorreu um erro inesperado.';
  
  // Deck Selector specific
  static const String completeCheckmark = 'Completo ✓';
  
  // Flashcard Screen specific
  static const String left = 'restantes';
  static const String audioNotAvailableError = 'Áudio não disponível';

  // Login Screen specific
  static const String createNewAccount = 'Criar nova conta';
  
  // Profile Screen specific
  static const String deleteAll = 'Deletar Tudo';
  static const String errorStartingTutorial = 'Erro inicializando tutorial';
  static const String errorLoggingOut = 'Err ao sair';
  
  // Register Screen specific
  static const String enterAPassword = 'Coloque uma senha';
  static const String operationNotAllowed = 'Email/senha não ativo.';

  // Review Screen specific
  static const String cardsLowercase = 'cartas';

  // Notification settings
  static const String notifications = 'Notificações';
  static const String notificationsDescription = 'Receba notificações quando seus cartões estiverem prontos para revisão';
  static const String notificationsEnabled = 'Notificações ativadas';
  static const String notificationsDisabled = 'Notificações desativadas';

  // ── Onboarding ────────────────────────────────────────────────────────────

  // Screen 1 — What it does
  static const String onboardingTitle1 = 'Aprenda mais rápido com\nrepetição espaçada';
  static const String onboardingBody1 =
      'O FlashLingo mostra cada palavra no momento certo — antes que você esqueça. Você estuda menos e lembra mais.';

  // Screen 2 — How cards work
  static const String onboardingTitle2 = 'Três gestos,\nsó isso';
  static const String onboardingBody2 =
      'Cada carta tem um objetivo: decidir se você sabia a resposta.';
  static const String onboardingActionTap = 'Toque — revelar a resposta';
  static const String onboardingActionSwipeRight = 'Deslize direita — acertei ✓';
  static const String onboardingActionSwipeLeft = 'Deslize esquerda — preciso praticar';

  // Screen 3 — The Leitner boxes
  static const String onboardingTitle3 = 'As cartas sobem por\n5 caixas';
  static const String onboardingBody3 =
      'Acerte uma carta e ela sobe para uma caixa maior, revisada com menos frequência. Erre e ela volta. Caixa 5 significa que você realmente aprendeu.';

  // Screen 4 — Daily habit
  static const String onboardingTitle4 = 'Dois minutos por dia\njá são suficientes';
  static const String onboardingBody4 =
      'O algoritmo espaça as revisões para que se acumulem aos poucos. Volte todo dia e seu vocabulário vai crescer sozinho.';

  // CTA
  static const String onboardingGetStarted = 'Começar';
}