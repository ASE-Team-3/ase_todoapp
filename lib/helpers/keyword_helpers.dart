class KeywordGenerator {
  static const List<String> _stopwords = [
    'the',
    'and',
    'a',
    'an',
    'to',
    'of',
    'in',
    'on',
    'for',
    'with',
    'at',
    'by',
    'from',
    'about',
    'as',
    'is',
    'it',
    'this',
    'that',
    'are',
    'was',
    'be',
    'or',
    'not',
    'but',
    'we',
    'you',
    'they',
    'can',
    'have',
    'has',
    'will',
    'would',
    'should',
    'could',
    'been',
    'if',
    'any',
    'some',
    'more',
    'their',
    'also',
    'which',
    'such',
    'those',
    'these',
    'however',
    'there',
    'thus'
  ];

  /// Generates up to 5 combined keywords: bigrams and single keywords based on frequency.
  static List<String> generate(String title, String description) {
    // Preprocess text: Combine title and description.
    final combinedText = "$title $description".toLowerCase();

    // Split into words, remove punctuation, and filter stopwords.
    final words = combinedText
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(RegExp(r'\s+')) // Split by whitespace
        .where((word) => word.length > 3 && !_stopwords.contains(word))
        .toList();

    // Count frequencies for single keywords and bigrams.
    final singleKeywordFrequency = _countFrequencies(words);
    final bigramFrequency = _countFrequencies(_generateBigrams(words));

    // Combine and sort both single keywords and bigrams by frequency.
    final combinedFrequency = <String, int>{};
    combinedFrequency.addAll(singleKeywordFrequency);
    bigramFrequency.forEach((bigram, count) {
      combinedFrequency[bigram] = (combinedFrequency[bigram] ?? 0) + count;
    });

    final sortedKeywords = combinedFrequency.keys.toList()
      ..sort((a, b) => combinedFrequency[b]!.compareTo(combinedFrequency[a]!));

    // Return the top 5 combined keywords.
    return sortedKeywords.take(5).toList();
  }

  /// Generate bigrams (two-word phrases) from a list of words.
  static List<String> _generateBigrams(List<String> words) {
    final List<String> bigrams = [];
    for (int i = 0; i < words.length - 1; i++) {
      bigrams.add("${words[i]} ${words[i + 1]}");
    }
    return bigrams;
  }

  /// Count word frequencies for any list of strings.
  static Map<String, int> _countFrequencies(List<String> words) {
    final wordFrequency = <String, int>{};
    for (var word in words) {
      wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
    }
    return wordFrequency;
  }
}
