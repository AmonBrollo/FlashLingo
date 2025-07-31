class Flashcard {
  final String english;
  final String portuguese;
  final String hungarian;
  final String? imagePath;

  Flashcard({
    required this.english,
    required this.portuguese,
    required this.hungarian,
    required this.imagePath,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      english: json['english'],
      portuguese: json['portuguese'],
      hungarian: json['hungarian'],
      imagePath: null,
    );
  }
}
