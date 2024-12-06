import 'package:app/providers/task_provider.dart';
import 'package:app/services/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AITaskCreateView extends StatelessWidget {
  const AITaskCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController aiPromptController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task with AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Describe your task and subtasks:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aiPromptController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'E.g., Plan my research project with subtasks for literature review, analysis, and reporting.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final userInput = aiPromptController.text.trim();
                if (userInput.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a task description.')),
                  );
                  return;
                }

                try {
                  // Call OpenAI Service
                  final openAIService =
                      Provider.of<OpenAIService>(context, listen: false);
                  final aiGeneratedTask =
                      await openAIService.createTaskFromPrompt(userInput);

                  // Show confirmation dialog with task details
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('AI-Generated Task'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Title: ${aiGeneratedTask.title}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Description: ${aiGeneratedTask.description}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            if (aiGeneratedTask.deadline != null)
                              Text(
                                'Deadline: ${aiGeneratedTask.deadline}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            if (aiGeneratedTask.flexibleDeadline != null)
                              Text(
                                'Flexible Deadline: ${aiGeneratedTask.flexibleDeadline}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            const SizedBox(height: 10),
                            Text(
                              'Priority: ${aiGeneratedTask.priority == 1 ? "High" : aiGeneratedTask.priority == 2 ? "Medium" : "Low"}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            if (aiGeneratedTask.keywords.isNotEmpty)
                              Text(
                                'Keywords: ${aiGeneratedTask.keywords.join(", ")}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            const SizedBox(height: 10),
                            if (aiGeneratedTask.subTasks.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Subtasks:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  ...aiGeneratedTask.subTasks.map((subTask) {
                                    return Text(
                                      '- ${subTask.title}: ${subTask.description}',
                                    );
                                  }),
                                ],
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Save the generated task
                            final taskProvider = Provider.of<TaskProvider>(
                                context,
                                listen: false);
                            taskProvider.addTask(aiGeneratedTask);

                            Navigator.pop(context); // Close dialog
                            Navigator.pop(
                                context); // Go back to previous screen

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Task created successfully!')),
                            );
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating task: $e')),
                  );
                }
              },
              child: const Text('Generate Task'),
            ),
          ],
        ),
      ),
    );
  }
}
