import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/task.dart';
import 'package:app/services/task_firestore_service.dart';
import 'package:app/views/tasks/task_detail_view.dart';
import 'package:app/services/research_service.dart'; // Import ResearchService


class ProjectView extends StatefulWidget {
  const ProjectView({super.key});

  @override
  State<ProjectView> createState() => _ProjectViewState();
}

class _ProjectViewState extends State<ProjectView> {
  final TaskFirestoreService _taskService = TaskFirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final researchService = ResearchService(apiUrl: '', apiKey: ''); // Initialize ResearchService instance
  String? selectedProjectId; // Stores the currently selected project ID
  List<Map<String, String>> userProjects = []; // Stores user projects for dropdown
  List<Task> pendingTasks = []; // Stores tasks marked as pending
  List<Task> completedTasks = []; // Stores tasks marked as completed
  Map<String, String> userNames = {}; // Cache for user names fetched using user IDs

  @override
  void initState() {
    super.initState();
    _fetchUserProjects(); // Fetch projects when the view loads
  }

  /// Fetch projects created by the current user
  Future<void> _fetchUserProjects() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("No user logged in.");
      return;
    }

    try {

      // Fetch projects where the user is assigned (arrayContains)
      final assignedProjects = await _db
          .collection('projects')
          .where('members', arrayContains: currentUser.uid) // Corrected to 'members'
          .get();

      // Combine both project lists and avoid duplicates
      final allProjects = {
        ...assignedProjects.docs,
      };

      setState(() {
        userProjects = allProjects.map((doc) {
          return {
            'id': doc.id.toString(),
            'name': (doc['name'] ?? 'Unnamed Project').toString(),
          };
        }).toList();
      });

      print("Fetched ${userProjects.length} projects.");
    } catch (e) {
      print("Error fetching user projects: $e");
    }
  }


  /// Fetch tasks under the selected project and categorize them
  Future<void> _getTasksForProject(String projectId) async {
    try {
      print("Fetching tasks for project ID: $projectId");

      // Fetch tasks where the projectId matches
      final snapshot = await _db
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();

      print("Fetched ${tasks.length} tasks for project.");

      // Fetch user names for assigned users
      await _fetchUserNames(tasks);

      // Categorize tasks into pending and completed
      setState(() {
        pendingTasks = tasks.where((task) => !task.isCompleted).toList();
        completedTasks = tasks.where((task) => task.isCompleted).toList();
      });

      print("Pending tasks: ${pendingTasks.length}, Completed tasks: ${completedTasks.length}");
    } catch (e) {
      print("Error fetching tasks for project: $e");
    }
  }

  /// Fetch user names based on the assigned user IDs in tasks
  Future<void> _fetchUserNames(List<Task> tasks) async {
    final userIds = tasks
        .where((task) => task.assignedTo != null)
        .map((task) => task.assignedTo!)
        .toSet(); // Get unique user IDs

    for (final userId in userIds) {
      if (!userNames.containsKey(userId)) {
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          setState(() {
            userNames[userId] = userDoc['name'] ?? 'Unknown User';
          });
          print("Fetched user name for ID $userId: ${userNames[userId]}");
        } catch (e) {
          print("Error fetching user name for ID $userId: $e");
          userNames[userId] = 'Unknown User';
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project View"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Project",
                border: OutlineInputBorder(),
              ),
              value: selectedProjectId,
              items: userProjects.map((project) {
                return DropdownMenuItem<String>(
                  value: project['id'],
                  child: Text(project['name'] ?? 'Unnamed Project'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProjectId = value;
                  pendingTasks = [];
                  completedTasks = [];
                  userNames.clear();
                });
                if (value != null) {
                  _getTasksForProject(value);
                }
              },
            ),
            const SizedBox(height: 20),

            // Task Lists
            if (selectedProjectId != null) ...[
              _buildTaskCategory("Pending Tasks", pendingTasks),
              const SizedBox(height: 16),
              _buildTaskCategory("Completed Tasks", completedTasks),
            ] else
              const Center(child: Text("Please select a project to view tasks.")),
          ],
        ),
      ),
    );
  }

  /// Build task list for each category
  Widget _buildTaskCategory(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        tasks.isEmpty
            ? const Text("No tasks found.")
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final assignedUserName = userNames[task.assignedTo] ?? "Loading...";

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailView(taskId: task.id),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Due Date: ${task.deadline?.toLocal().toString().split(' ')[0] ?? 'N/A'}"),
                      Text("Assigned To: $assignedUserName"),
                    ],
                  ),
                  trailing: Icon(
                    task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: task.isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}