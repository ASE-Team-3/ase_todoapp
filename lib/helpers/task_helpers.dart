import 'dart:developer';

import 'package:app/models/task.dart';
import 'package:app/utils/keyword_generator.dart';
import 'package:app/services/research_service.dart';

/// Handles category changes, including generating keywords for research tasks.
Future<Task> handleCategoryChange({
  required Task task,
  required String newCategory,
  required String title,
  required String description,
  required ResearchService researchService,
}) async {
  if (newCategory == "Research") {
    // Generate keywords for research tasks
    final generatedKeywords = KeywordGenerator.generate(title, description);

    // Fetch related research papers
    try {
      final relatedPapers =
          await researchService.fetchRelatedResearch(generatedKeywords);
      log('Fetched related research papers for updated task: ${task.title}');
      // Optionally attach related research to the task or UI
    } catch (e) {
      log('Failed to fetch related research papers: $e');
    }

    // Return updated task with keywords
    return task.copyWith(keywords: generatedKeywords);
  } else {
    // Clear keywords for non-research categories
    return task.copyWith(keywords: []);
  }
}

/// Calculates the deadline based on a flexible deadline value.
DateTime? calculateFlexibleDeadline(String? flexibleDeadline) {
  if (flexibleDeadline == null) return null;

  // Example logic: Adjust based on flexibleDeadline value
  switch (flexibleDeadline.toLowerCase()) {
    case "today":
      return DateTime.now().toUtc();
    case "this week":
      final now = DateTime.now();
      final endOfWeek = now.add(Duration(days: 7 - now.weekday));
      return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day).toUtc();
    default:
      return null;
  }
}