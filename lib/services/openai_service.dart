import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/task.dart';

class OpenAIService {
  static const String apiUrl = "https://api.openai.com/v1/chat/completions";

  Future<Map<String, String>> analyzeTask(Task task) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key is missing or invalid');
    }

    // Calculate remaining time
    final now = DateTime.now().toUtc();
    final deadline = task.deadline?.toUtc();
    final duration = deadline != null ? deadline.difference(now) : null;

    final daysRemaining = duration?.inDays ?? -1;
    final hoursRemaining = duration?.inHours.remainder(24) ?? -1;
    final minutesRemaining = duration?.inMinutes.remainder(60) ?? -1;

    log("DEBUG: Task ID: ${task.id}");
    log("DEBUG: Task Deadline (UTC): $deadline");
    log("DEBUG: Current Time (UTC): $now");
    log("DEBUG: Days Remaining: $daysRemaining");
    log("DEBUG: Hours Remaining: $hoursRemaining");
    log("DEBUG: Minutes Remaining: $minutesRemaining");

    final prompt =
        _generatePrompt(task, daysRemaining, hoursRemaining, minutesRemaining);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-4", // Correct model
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 150,
          "temperature": 0.2, // Short, deterministic responses
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        log("API Response: $responseBody");

        if (responseBody['choices'] == null ||
            responseBody['choices'].isEmpty) {
          throw Exception('No choices returned by the API');
        }

        final generatedText =
            responseBody['choices'][0]['message']?['content']?.trim();
        if (generatedText == null) {
          throw Exception('AI did not return any content');
        }

        return _parseResponse(generatedText);
      } else {
        log("API response error: ${response.body}");
        final error = jsonDecode(response.body)['error']['message'];
        throw Exception('Failed to fetch AI feedback: $error');
      }
    } catch (e) {
      log("Exception in OpenAIService: $e");
      rethrow;
    }
  }

  String _generatePrompt(
      Task task, int daysRemaining, int hoursRemaining, int minutesRemaining) {
    // Format remaining time
    String timeRemaining;
    if (daysRemaining > 0) {
      timeRemaining =
          "$daysRemaining days, $hoursRemaining hours, and $minutesRemaining minutes remaining.";
    } else if (hoursRemaining > 0) {
      timeRemaining =
          "$hoursRemaining hours and $minutesRemaining minutes remaining.";
    } else if (minutesRemaining > 0) {
      timeRemaining = "$minutesRemaining minutes remaining.";
    } else {
      timeRemaining = "Deadline has passed.";
    }

    // Include keywords if available
    String keywords = task.keywords.isNotEmpty
        ? "Keywords: ${task.keywords.join(", ")}"
        : "No specific keywords provided.";

    // Include subtasks if available
    String subtasks = task.subTasks.isNotEmpty
        ? "Subtasks: ${task.subTasks.map((st) => st.title).join(", ")}"
        : "No subtasks listed.";

    // Include repeating task details
    String repeatingInfo = task.isRepeating
        ? "This task repeats every ${task.repeatInterval ?? "custom interval"}."
        : "This is a one-time task.";

    // Include category and priority
    String priority = task.priority == 1
        ? "High"
        : task.priority == 2
            ? "Medium"
            : "Low";

    return '''
Task Analysis:
Title: "${task.title}"
Category: "${task.category}"
Priority: "$priority"
Description: "${task.description}"
Time Remaining: $timeRemaining
$repeatingInfo
$keywords
$subtasks

Be concise. Limit your response to two sentences per item.

Provide:
1. A motivational message tailored to the task details.
2. A recommendation on how to complete the task based on the attributes provided.
    ''';
  }

  Map<String, String> _parseResponse(String response) {
    String motivationalMessage = "";
    String recommendations = "";

    final motivationalRegex = RegExp(r"1\.\s*([^2]+)", dotAll: true);
    final recommendationsRegex = RegExp(r"2\.\s*(.+)", dotAll: true);

    final motivationalMatch = motivationalRegex.firstMatch(response);
    if (motivationalMatch != null) {
      motivationalMessage = motivationalMatch.group(1)?.trim() ?? "";
    }

    final recommendationsMatch = recommendationsRegex.firstMatch(response);
    if (recommendationsMatch != null) {
      recommendations = recommendationsMatch.group(1)?.trim() ?? "";
    }

    log("Parsed Motivational Message: $motivationalMessage");
    log("Parsed Recommendations: $recommendations");

    return {
      "message": motivationalMessage.isNotEmpty
          ? motivationalMessage
          : "No motivational message available.",
      "recommendation": recommendations.isNotEmpty
          ? recommendations
          : "No recommendations available.",
    };
  }
}
