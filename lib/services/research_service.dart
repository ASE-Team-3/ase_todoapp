import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ResearchService {
  final String apiUrl;
  final String apiKey;

  ResearchService({required this.apiUrl, required this.apiKey});

  /// Fetches a new research paper suggestion daily.
  ///
  /// The function fetches related research papers based on the provided
  /// keywords. It ensures that the paper suggested to the user is new
  /// (not repeated from the last suggestion) and stores the current suggestion
  /// in shared preferences for future reference.
  ///
  /// - Returns: A `Map<String, String>` containing information about the paper
  ///   (e.g., title, author, publish date, and URL).
  Future<Map<String, String>> fetchDailyResearchPaper(
      List<String> keywords) async {
    final papers = await fetchRelatedResearch(keywords);
    if (papers.isEmpty) {
      throw Exception("No research papers found.");
    }

    // Retrieve the last suggested paper's URL from local storage
    final prefs = await SharedPreferences.getInstance();
    final lastPaperUrl = prefs.getString('lastSuggestedPaperUrl');

    // Find the next paper to suggest
    final nextPaper = _getNextPaper(papers, lastPaperUrl);

    // Store the new suggestion's URL in local storage
    if (nextPaper['url'] != null) {
      await prefs.setString('lastSuggestedPaperUrl', nextPaper['url']!);
    }

    return nextPaper;
  }

  /// Fetches related research papers from the Scopus API.
  ///
  /// This version targets TITLE, ABSTRACT, and KEYWORDS for better relevance.
  ///
  /// - [keywords]: List of keywords for querying research papers.
  /// - Returns: A list of maps where each map contains paper details such as
  ///   title, authors, publish date, and DOI URL.
  Future<List<Map<String, String>>> fetchRelatedResearch(
      List<String> keywords) async {
    if (keywords.isEmpty) return [];

    final refinedQuery = _buildRefinedQuery(keywords);
    int start = 0; // Pagination start index
    const int pageSize = 25; // Number of results per page
    const int maxResults = 100; // Limit to avoid too many requests
    List<Map<String, String>> papers = [];

    log("INFO: Fetching research papers with query: $refinedQuery");

    try {
      while (start < maxResults) {
        final uri = Uri.parse(
            "$apiUrl/search/scopus?query=$refinedQuery&start=$start&count=$pageSize");

        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'X-ELS-APIKey': apiKey,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final fetchedPapers = _parseResearchPapers(data);
          if (fetchedPapers.isEmpty) break; // Stop if no more results

          papers.addAll(fetchedPapers);
          start += pageSize;
        } else {
          log("ERROR: Failed to fetch research papers. Status: ${response.statusCode}");
          break; // Exit loop on failure
        }
      }

      log("INFO: Successfully fetched ${papers.length} research papers.");
      return _removeDuplicates(papers);
    } catch (e) {
      log("EXCEPTION: Error fetching research papers: $e");
      throw Exception('Error fetching research papers: $e');
    }
  }

  /// Builds a refined query string to search in TITLE, ABSTRACT, and KEYWORDS.
  String _buildRefinedQuery(List<String> keywords) {
    // Combine keywords into TITLE-ABS-KEY queries using AND operator
    final queryParts = keywords.map((k) => 'TITLE-ABS-KEY("$k")').toList();
    return queryParts.join(' AND ');
  }

  /// Removes duplicate papers based on title and DOI.
  List<Map<String, String>> _removeDuplicates(
      List<Map<String, String>> papers) {
    final seen = <String>{};
    final uniquePapers = <Map<String, String>>[];

    for (var paper in papers) {
      final uniqueIdentifier = "${paper['title']}_${paper['doi']}";
      if (!seen.contains(uniqueIdentifier)) {
        seen.add(uniqueIdentifier);
        uniquePapers.add(paper);
      }
    }

    return uniquePapers;
  }

  /// Parses research papers from the API response data.
  ///
  /// This function extracts relevant details (title, author, publish date, and
  /// DOI URL) from the API's JSON response. It also sorts the papers by
  /// publish date in descending order, ensuring the latest papers are listed first.
  ///
  /// - Returns: A list of maps where each map contains paper details.
  List<Map<String, String>> _parseResearchPapers(dynamic data) {
    final entries = data['search-results']['entry'] as List<dynamic>;
    final papers = entries.map((entry) {
      final doi = entry['prism:doi'] as String?;
      final url = doi != null ? 'https://doi.org/$doi' : null;

      return {
        'title': entry['dc:title'] as String? ?? 'No title available',
        'author': _extractAuthors(entry),
        'publishDate':
            entry['prism:coverDate'] as String? ?? 'No publish date available',
        'url': url ?? 'No DOI available',
      };
    }).toList();

    // Sort papers by publish date in descending order
    papers.sort((a, b) {
      final dateA = DateTime.tryParse(a['publishDate']!);
      final dateB = DateTime.tryParse(b['publishDate']!);
      return dateB?.compareTo(dateA ?? DateTime.now()) ?? 0;
    });

    return papers;
  }

  /// Extracts the authors of a research paper.
  ///
  /// This function retrieves the list of authors from the API response entry.
  /// If no authors are available, it returns a default message.
  ///
  /// - Returns: A string containing the authors' names, separated by commas.
  String _extractAuthors(Map<String, dynamic> entry) {
    final authors = entry['author'] as List<dynamic>?;
    if (authors == null || authors.isEmpty) {
      return 'No authors available';
    }
    return authors
        .map((author) => author['authname'] as String? ?? 'Unknown Author')
        .join(', ');
  }

  /// Determines the next research paper to suggest to the user.
  ///
  /// This function ensures that the paper suggested is new by comparing it
  /// against the last suggested paper. If the last paper is not found or no
  /// history exists, it returns the first paper in the list.
  ///
  /// - Returns: A `Map<String, String>` containing the next paper's details.
  Map<String, String> _getNextPaper(
      List<Map<String, String>> papers, String? lastPaperUrl) {
    if (lastPaperUrl == null) {
      return papers.first; // No history, suggest the first paper
    }

    for (int i = 0; i < papers.length; i++) {
      if (papers[i]['url'] == lastPaperUrl) {
        // Return the next paper or loop back to the first
        return papers[(i + 1) % papers.length];
      }
    }

    // If the last suggested paper is not found, return the first paper
    return papers.first;
  }
}
