class TopicNames {
  // Map of topics → language → display name
  static final Map<String, Map<String, String>> names = {
    "adjectives": {"english": "Adjectives", "portuguese": "Adjetivos"},
    "animals": {"english": "Animals", "portuguese": "Animais"},
    "art": {"english": "Art", "portuguese": "Arte"},
    "beverages": {"english": "Beverages", "portuguese": "Bebidas"},
    "body": {"english": "Body", "portuguese": "Corpo"},
    "clothing": {"english": "Clothing", "portuguese": "Roupas"},
    "days": {"english": "Days", "portuguese": "Dias"},
    "directions": {"english": "Directions", "portuguese": "Direções"},
    "electronics": {"english": "Electronics", "portuguese": "Eletrônicos"},
    "food": {"english": "Food", "portuguese": "Comida"},
    "home": {"english": "Home", "portuguese": "Casa"},
    "jobs": {"english": "Jobs", "portuguese": "Profissões"},
    "locations": {"english": "Locations", "portuguese": "Localizações"},
    "materials": {"english": "Materials", "portuguese": "Materiais"},
    "math": {"english": "Math", "portuguese": "Matemática"},
    "miscellaneous": {"english": "Miscellaneous", "portuguese": "Diversos"},
    "months": {"english": "Months", "portuguese": "Meses"},
    "nature": {"english": "Nature", "portuguese": "Natureza"},
    "numbers": {"english": "Numbers", "portuguese": "Números"},
    "people": {"english": "People", "portuguese": "Pessoas"},
    "pronouns": {"english": "Pronouns", "portuguese": "Pronomes"},
    "society": {"english": "Society", "portuguese": "Sociedade"},
    "time": {"english": "Time", "portuguese": "Tempo"},
    "transportation": {"english": "Transportation", "portuguese": "Transporte"},
    "verbs": {"english": "Verbs", "portuguese": "Verbos"},
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
