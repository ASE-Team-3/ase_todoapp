import 'dart:developer';
import 'package:app/models/attachment.dart';
import 'package:app/models/task.dart';
import 'package:app/services/research_service.dart';
import 'package:app/services/task_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCreateView extends StatefulWidget {
  final Task? task; // Task to edit, if provided
  final ResearchService researchService; // For research-related features

  const TaskCreateView({
    super.key,
    this.task,
    required this.researchService,
  });

  @override
  State<TaskCreateView> createState() => _TaskCreateViewState();
}

class _TaskCreateViewState extends State<TaskCreateView> {
  // Controllers for text input fields
  final TextEditingController titleTaskController = TextEditingController();
  final TextEditingController descriptionTaskController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();

  // State variables
  DateTime? selectedDeadline; // Task deadline
  List<Attachment> attachments = []; // Attachments list
  String? selectedAssignee; // Optional: Assigned user ID
  String? selectedProject; // Optional: Project ID
  String? selectedCategory = "General"; // Default category for tasks

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _initializeFieldsFromTask(widget.task!); // Initialize fields for editing
    }
  }

  /// Initialize form fields when editing an existing task
  void _initializeFieldsFromTask(Task task) {
    titleTaskController.text = task.title;
    descriptionTaskController.text = task.description;
    pointsController.text = task.points.toString();
    selectedDeadline = task.deadline;
    selectedAssignee = task.assignedTo;
    selectedProject = task.projectId;
    selectedCategory = task.category;
    attachments = List.from(task.attachments);
    log("Fields initialized with existing task data.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? "Create Task" : "Update Task"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Title", titleTaskController), // Title input
            const SizedBox(height: 12),
            _buildTextField("Description", descriptionTaskController, isMultiline: true), // Description input
            const SizedBox(height: 12),
            _buildProjectDropdown(), // Optional: Project dropdown
            const SizedBox(height: 12),
            _buildAssigneeDropdown(), // Optional: Assignee dropdown
            const SizedBox(height: 12),
            _buildDeadlinePicker(), // Deadline picker
            const SizedBox(height: 12),
            _buildCategoryDropdown(), // Category dropdown
            const SizedBox(height: 12),
            _buildSaveButton(), // Save button
          ],
        ),
      ),
    );
  }

  /// Builds a text field with a given label
  Widget _buildTextField(String label, TextEditingController controller, {bool isMultiline = false}) {
    return TextField(
      controller: controller,
      maxLines: isMultiline ? 3 : 1,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Project Dropdown: Fetches and displays projects owned by the current user
  Widget _buildProjectDropdown() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _fetchUserProjects(), // Fetch projects from Firestore
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          value: selectedProject,
          items: projects.map((project) {
            return DropdownMenuItem(
              value: project['id'],
              child: Text(project['name'] ?? "Unnamed Project"),
            );
          }).toList(),
          decoration: const InputDecoration(labelText: "Select Project (Optional)"),
          onChanged: (value) {
            setState(() => selectedProject = value);
            log("Selected Project ID: $value");
          },
        );
      },
    );
  }

  /// Assignee Dropdown: Fetches users and allows selection
  Widget _buildAssigneeDropdown() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _fetchUsers(), // Fetch users from Firestore
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          value: selectedAssignee,
          items: users.map((user) {
            return DropdownMenuItem(
              value: user['id'],
              child: Text(user['name'] ?? "Unknown User"),
            );
          }).toList(),
          decoration: const InputDecoration(labelText: "Assign To (Optional)"),
          onChanged: (value) {
            setState(() => selectedAssignee = value);
            log("Assigned User ID: $value");
          },
        );
      },
    );
  }

  /// Deadline Picker: Allows user to pick a date for the task deadline
  Widget _buildDeadlinePicker() {
    return ListTile(
      title: const Text("Deadline"),
      subtitle: Text(selectedDeadline != null
          ? selectedDeadline!.toLocal().toString()
          : "No deadline selected"),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() {
            selectedDeadline = pickedDate;
            log("Selected Deadline: ${pickedDate.toLocal()}");
          });
        }
      },
    );
  }

  /// Category Dropdown: Allows user to select a category for the task
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: ["General", "Research", "Project", "Personal"]
          .map((category) => DropdownMenuItem(value: category, child: Text(category)))
          .toList(),
      decoration: const InputDecoration(labelText: "Category"),
      onChanged: (value) {
        setState(() {
          selectedCategory = value;
          log("Selected Category: $value");
        });
      },
    );
  }

  /// Save Button: Saves or updates the task
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveOrUpdateTask,
      child: Text(widget.task == null ? "Save Task" : "Update Task"),
    );
  }

  /// Saves or updates a task in Firestore
  Future<void> _saveOrUpdateTask() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      log("Error: No user logged in.");
      return;
    }

    // Prepare task data
    final task = Task(
      title: titleTaskController.text,
      description: descriptionTaskController.text,
      deadline: selectedDeadline?.toUtc(),
      createdBy: currentUser.uid,
      assignedBy: currentUser.uid,
      assignedTo: selectedAssignee, // Optional
      projectId: selectedProject,   // Optional
      category: selectedCategory ?? "General",
      attachments: attachments,
    );

    try {
      final taskService = TaskFirestoreService();
      if (widget.task == null) {
        await taskService.addTask(task);
        log("Task created successfully.");
      } else {
        await taskService.updateTask(task);
        log("Task updated successfully.");
      }
      Navigator.pop(context);
    } catch (e) {
      log("Error saving task: $e");
    }
  }

  /// Fetches projects owned by the current user
  Future<List<Map<String, String>>> _fetchUserProjects() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    try {
      // Fetch projects owned by the current user
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('createdBy', isEqualTo: currentUser?.uid)
          .get();

      // Safely map the Firestore documents to List<Map<String, String>>
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id, // Project ID as String
          'name': doc['name']?.toString() ?? "Unnamed Project", // Project name as String
        };
      }).toList();
    } catch (e) {
      log("Error fetching projects: $e");
      return [];
    }
  }

  /// Fetches all users from Firestore
  Future<List<Map<String, String>>> _fetchUsers() async {
    try {
      // Fetch all user documents from the 'users' collection
      final snapshot = await FirebaseFirestore.instance.collection('users').get();

      // Map Firestore documents to List<Map<String, String>> with type safety
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id, // Firestore document ID (always a String)
          'name': doc['username']?.toString() ?? "Unknown User", // Cast username to String
        };
      }).toList();
    } catch (e) {
      log("Error fetching users: $e");
      return [];
    }
  }


  @override
  void dispose() {
    titleTaskController.dispose();
    descriptionTaskController.dispose();
    pointsController.dispose();
    super.dispose();
  }
}
