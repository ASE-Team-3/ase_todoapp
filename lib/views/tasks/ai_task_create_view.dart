import 'package:app/providers/task_provider.dart';
import 'package:app/services/openai_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AITaskCreateView extends StatelessWidget {
  const AITaskCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController aiPromptController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStr.createTaskWithAI),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStr.describeTask,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.primaryColor),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: aiPromptController,
                maxLines: null, // Allows for unlimited lines like a chat box
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText:
                      'E.g., Plan my research project with subtasks for literature review, analysis, and reporting.',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final userInput = aiPromptController.text.trim();
                if (userInput.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStr.enterTaskDescription)),
                  );
                  return;
                }

                try {
                  // Show loading modal
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AlertDialog(
                      backgroundColor: Colors.white,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 20),
                          Text(AppStr.generatingTaskWait,
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                  );

                  // Call OpenAI Service
                  final openAIService =
                      Provider.of<OpenAIService>(context, listen: false);
                  final aiGeneratedTask =
                      await openAIService.createTaskFromPrompt(userInput);

                  Navigator.pop(context); // Close loading modal

                  // Show confirmation dialog with task details
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text(AppStr.taskGenerated),
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
                          child: const Text(AppStr.cancel),
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
                              const SnackBar(content: Text(AppStr.taskCreated)),
                            );
                          },
                          child: const Text(AppStr.confirm),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Close loading modal
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppStr.errorCreatingTask}: $e')),
                  );
                }
              },
              child: const Text(AppStr.generateTask),
            ),
          ],
        ),
      ),
    );
  }
}
