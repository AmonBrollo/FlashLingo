class TopicNames {
  // Map of topics → language → display name
  static final Map<String, Map<String, String>> names = {
    "adjectives": {
      "english": "Adjectives",
      "portuguese": "Adjetivos",
      "spanish": "Adjetivos",
    },
    "animals": {
      "english": "Animals",
      "portuguese": "Animais",
      "spanish": "Animales",
    },
    "art": {
      "english": "Art",
      "portuguese": "Arte",
      "spanish": "Arte",
    },
    "beverages": {
      "english": "Beverages",
      "portuguese": "Bebidas",
      "spanish": "Bebidas",
    },
    "body": {
      "english": "Body",
      "portuguese": "Corpo",
      "spanish": "Cuerpo",
    },
    "clothing": {
      "english": "Clothing",
      "portuguese": "Roupas",
      "spanish": "Ropa",
    },
    "days": {
      "english": "Days",
      "portuguese": "Dias",
      "spanish": "Días",
    },
    "directions": {
      "english": "Directions",
      "portuguese": "Direções",
      "spanish": "Direcciones",
    },
    "electronics": {
      "english": "Electronics",
      "portuguese": "Eletrônicos",
      "spanish": "Electrónicos",
    },
    "food": {
      "english": "Food",
      "portuguese": "Comida",
      "spanish": "Comida",
    },
    "home": {
      "english": "Home",
      "portuguese": "Casa",
      "spanish": "Casa",
    },
    "jobs": {
      "english": "Jobs",
      "portuguese": "Profissões",
      "spanish": "Profesiones",
    },
    "locations": {
      "english": "Locations",
      "portuguese": "Localizações",
      "spanish": "Ubicaciones",
    },
    "materials": {
      "english": "Materials",
      "portuguese": "Materiais",
      "spanish": "Materiales",
    },
    "math": {
      "english": "Math",
      "portuguese": "Matemática",
      "spanish": "Matemáticas",
    },
    "miscellaneous": {
      "english": "Miscellaneous",
      "portuguese": "Diversos",
      "spanish": "Varios",
    },
    "months": {
      "english": "Months",
      "portuguese": "Meses",
      "spanish": "Meses",
    },
    "nature": {
      "english": "Nature",
      "portuguese": "Natureza",
      "spanish": "Naturaleza",
    },
    "numbers": {
      "english": "Numbers",
      "portuguese": "Números",
      "spanish": "Números",
    },
    "people": {
      "english": "People",
      "portuguese": "Pessoas",
      "spanish": "Personas",
    },
    "pronouns": {
      "english": "Pronouns",
      "portuguese": "Pronomes",
      "spanish": "Pronombres",
    },
    "society": {
      "english": "Society",
      "portuguese": "Sociedade",
      "spanish": "Sociedad",
    },
    "time": {
      "english": "Time",
      "portuguese": "Tempo",
      "spanish": "Tiempo",
    },
    "transportation": {
      "english": "Transportation",
      "portuguese": "Transporte",
      "spanish": "Transporte",
    },
    "verbs": {
      "english": "Verbs",
      "portuguese": "Verbos",
      "spanish": "Verbos",
    },
  };

  // Optional: list of all topic keys
  static List<String> get allTopics => names.keys.toList();

  /// Returns the topic display name in the given language.
  /// Falls back to English if the requested language is missing.
  static String getName(String topicKey, String language) {
    final topicMap = names[topicKey];
    if (topicMap == null) return topicKey; // fallback if topicKey unknown
    return topicMap[language] ?? topicMap['english'] ?? topicKey;
  }
}