import 'package:app/services/research_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/views/tasks/ai_task_create_view.dart';
import 'package:app/views/tasks/task_create_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Fab extends StatelessWidget {
  const Fab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showTaskCreationOptions(context);
      },
      child: Material(
        borderRadius: BorderRadius.circular(15),
        elevation: 10,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Task',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primaryColor),
                title: const Text('Add Task Manually'),
                onTap: () {
                  // Close the modal
                  Navigator.pop(context);

                  // Access ResearchService from the provider
                  final researchService =
                      Provider.of<ResearchService>(context, listen: false);

                  // Navigate to TaskCreateView
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => TaskCreateView(
                        researchService: researchService,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: AppColors.primaryColor),
                title: const Text('Create Task with AI'),
                onTap: () {
                  // Close the modal
                  Navigator.pop(context);

                  // Navigate to AI Chat Task Creation Screen
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const AITaskCreateView(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
