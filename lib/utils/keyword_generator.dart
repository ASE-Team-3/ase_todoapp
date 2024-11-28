class KeywordGenerator {
  /// Generates a list of keywords from the given title and description.
  static List<String> generate(String title, String description) {
    final combinedText = "$title $description".toLowerCase();
    final words = combinedText.split(RegExp(r'\s+')).toSet(); // Unique words
    final keywords = words.where((word) => word.length > 3).toList(); // Filter
    return keywords.take(5).toList(); // Return up to 5 keywords
  }
}
