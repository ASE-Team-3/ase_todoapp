import 'dart:convert';
import 'package:http/http.dart' as http;

class ResearchService {
  final String apiUrl;
  final String apiKey;

  ResearchService({required this.apiUrl, required this.apiKey});

  Future<List<Map<String, String>>> fetchRelatedResearch(
      List<String> keywords) async {
    final query = keywords.join(' '); // Join keywords for the search query
    final uri = Uri.parse('$apiUrl/search/scopus?query=$query');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-ELS-APIKey': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseResearchPapers(data);
      } else {
        throw Exception(
            'Failed to fetch research papers. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching research papers: $e');
    }
  }

  List<Map<String, String>> _parseResearchPapers(dynamic data) {
    final entries = data['search-results']['entry'] as List<dynamic>;
    return entries.map((entry) {
      final doi = entry['prism:doi'] as String?; // Extract DOI
      final url = doi != null ? 'https://doi.org/$doi' : null;

      return {
        'title': entry['dc:title'] as String? ?? 'No title available',
        'url': url ?? 'No DOI available',
      };
    }).toList();
  }
}
