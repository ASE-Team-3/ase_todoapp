import 'dart:convert';
import 'dart:developer';
import 'package:app/models/subtask.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/task.dart';
import 'package:app/utils/deadline_utils.dart'; // Import the utility for deadlines

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

  Future<Task> createTaskFromPrompt(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      log("ERROR: Missing or invalid API key");
      throw Exception('API key is missing or invalid');
    }

    // Refine the GPT prompt to match Task and SubTask fields
    final refinedPrompt = '''
You are an assistant creating task plans for users. Use the following structured format for your response:

Task:
- Title: [Task title]
- Description: [Task description]
- Deadline: [YYYY-MM-DD or flexible deadline description]
- Priority: [High, Medium, Low]
- Keywords: [Comma-separated keywords]
- Category: [Category of the task]
- Subtasks:
  - Title: [Subtask title]
  - Description: [Subtask description]
  - Type: [common, paper, other]
  - Author: [If type is paper, provide the author; otherwise leave empty]
  - Publish Date: [If type is paper, provide publish date in YYYY-MM-DD; otherwise leave empty]
  - URL: [If type is paper, provide URL; otherwise leave empty]
  - Completed: [true/false]

Respond strictly in this format.

User Input: $prompt
  ''';

    log("INFO: Sending refined request to OpenAI API with prompt: $refinedPrompt");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-4",
          "messages": [
            {
              "role": "system",
              "content": "You are a structured task planning assistant."
            },
            {"role": "user", "content": refinedPrompt}
          ],
          "max_tokens": 500,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log("DEBUG: OpenAI API response: $responseBody");

        if (responseBody['choices'] == null ||
            responseBody['choices'].isEmpty) {
          log("ERROR: OpenAI API returned no choices");
          throw Exception('No choices returned from OpenAI API');
        }

        final generatedText = responseBody['choices'][0]['message']['content'];
        if (generatedText == null || generatedText.isEmpty) {
          log("ERROR: OpenAI API returned empty content");
          throw Exception('AI did not generate any content');
        }

        log("INFO: AI-generated structured content: $generatedText");

        // Parse the AI response into a Task object
        final task = _parseGeneratedTask(generatedText);
        log("INFO: Successfully created Task: ${task.title}");
        return task;
      } else {
        log("ERROR: OpenAI API request failed with status: ${response.statusCode}");
        final error = jsonDecode(response.body)['error']['message'];
        log("ERROR: OpenAI API error message: $error");
        throw Exception('Failed to generate task: $error');
      }
    } catch (e) {
      log("EXCEPTION: Error during task generation: $e");
      rethrow;
    }
  }

  Task _parseGeneratedTask(String responseText) {
    log("DEBUG: Parsing AI-generated task content");

    try {
      // Split the response text into lines
      final lines = responseText
          .split("\n")
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        log("ERROR: No valid data found in AI response");
        throw Exception("Failed to parse response: No valid data found.");
      }

      log("INFO: Parsed lines from AI response: $lines");

      // Fetch current user's ID
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "Unknown";

      log("INFO: Current User ID: $currentUserId");

      // Helper to safely extract field values
      String getFieldValue(String prefix) {
        final line = lines.firstWhere(
          (line) => line.startsWith(prefix),
          orElse: () => "$prefix ",
        );
        return line.replaceFirst(prefix, "").trim();
      }

      // Extract task fields with fallback defaults
      final title = getFieldValue("- Title:").isNotEmpty
          ? getFieldValue("- Title:")
          : "Untitled Task"; // Default if title is missing
      final description = getFieldValue("- Description:").isNotEmpty
          ? getFieldValue("- Description:")
          : "No description provided."; // Default if description is missing
      final deadline = getFieldValue("- Deadline:");
      final priority = getFieldValue("- Priority:");
      final keywords = getFieldValue("- Keywords:")
          .split(",")
          .map((keyword) => keyword.trim())
          .where((keyword) => keyword.isNotEmpty)
          .toList();
      final category = getFieldValue("- Category:").isNotEmpty
          ? getFieldValue("- Category:")
          : "General"; // Default category if missing

      // Handle deadline: Parse specific or flexible deadlines
      DateTime? parsedDeadline;
      String? flexibleDeadline;
      if (deadline.isNotEmpty) {
        parsedDeadline = DateTime.tryParse(deadline);
        if (parsedDeadline == null) {
          flexibleDeadline = deadline; // Assume it's a flexible deadline string
          parsedDeadline = calculateDeadlineFromFlexible(flexibleDeadline) ??
              DateTime.now().add(const Duration(days: 7)); // Default fallback
        }
      } else {
        log("WARNING: Deadline not provided, assigning default deadline");
        parsedDeadline = DateTime.now().add(const Duration(days: 7)); // Default
      }

      // Parse subtasks
      final subTasks = <SubTask>[];
      bool isSubTaskSection = false;
      SubTask? currentSubTask;

      for (final line in lines) {
        if (line.startsWith("- Subtasks:")) {
          isSubTaskSection = true;
          continue; // Skip the "Subtasks" header
        }

        if (isSubTaskSection) {
          if (line.startsWith("- Title:")) {
            // Save the current subtask if it exists
            if (currentSubTask != null) {
              subTasks.add(currentSubTask);
            }
            // Start a new subtask
            currentSubTask = SubTask(
              title: line.replaceFirst("- Title:", "").trim(),
              description: "",
              type: SubTaskType.common,
              isCompleted: false,
            );
          } else if (line.startsWith("- Description:") &&
              currentSubTask != null) {
            currentSubTask = currentSubTask.copyWith(
                description: line.replaceFirst("- Description:", "").trim());
          } else if (line.startsWith("- Type:") && currentSubTask != null) {
            final typeString =
                line.replaceFirst("- Type:", "").trim().toLowerCase();
            currentSubTask = currentSubTask.copyWith(
                type: SubTaskType.values.firstWhere(
              (type) => type.toString().split('.').last == typeString,
              orElse: () => SubTaskType.common,
            ));
          } else if (line.startsWith("- Completed:") &&
              currentSubTask != null) {
            final completed =
                line.replaceFirst("- Completed:", "").trim().toLowerCase() ==
                    "true";
            currentSubTask = currentSubTask.copyWith(isCompleted: completed);
          }
        }
      }

      // Add the last subtask if it exists
      if (currentSubTask != null) {
        subTasks.add(currentSubTask);
      }

      // Handle priority fallback
      final parsedPriority = priority.toLowerCase() == "high"
          ? 1
          : priority.toLowerCase() == "low"
              ? 3
              : 2; // Default to medium if not specified

      // Create Task object
      final task = Task(
        title: title,
        description: description,
        deadline: parsedDeadline,
        flexibleDeadline: flexibleDeadline,
        priority: parsedPriority,
        createdBy: currentUserId,
        keywords: keywords,
        category: category,
        subTasks: subTasks,
      );

      log("INFO: Successfully parsed Task: ${task.title}, with ${task.subTasks.length} subtasks");
      return task;
    } catch (e) {
      log("EXCEPTION: Error parsing AI-generated task: $e");
      throw Exception("Error parsing AI-generated task: $e");
    }
  }
}
