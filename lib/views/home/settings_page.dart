import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPageState extends StatefulWidget {
  const SettingsPageState({super.key});

  @override
  State<SettingsPageState> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPageState> {
  // Controllers for input fields
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectDescriptionController = TextEditingController();

  // State variables
  List<String> selectedMembers = []; // Selected user IDs
  List<Map<String, String>> users = []; // List of all users fetched from Firestore
  List<DocumentSnapshot> projects = []; // List of projects created by the current user
  String? selectedProjectId; // The ID of the project being edited

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users for member assignment dropdown
    _fetchProjects(); // Fetch existing projects
  }

  /// Fetch users for the member dropdown
  Future<void> _fetchUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        users = snapshot.docs.map((doc) {
          return {
            'id': doc['userId']?.toString() ?? '',
            'name': doc['name']?.toString() ?? 'Unknown User',
          };
        }).toList();
      });
      log("Fetched ${users.length} users successfully.");
    } catch (e) {
      log("Error fetching users: $e");
    }
  }

  /// Fetch projects created by the current user
  Future<void> _fetchProjects() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('createdBy', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        projects = snapshot.docs;
      });
      log("Fetched ${projects.length} projects.");
    } catch (e) {
      log("Error fetching projects: $e");
    }
  }

  /// Save or update a project
  Future<void> _saveProject() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final projectName = projectNameController.text.trim();
    final projectDescription = projectDescriptionController.text.trim();

    if (projectName.isEmpty || projectDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project name and description are required.")),
      );
      return;
    }

    try {
      // Ensure creator's user ID is always in the members list
      final updatedMembers = List<String>.from(selectedMembers);
      if (!updatedMembers.contains(currentUser.uid)) {
        updatedMembers.add(currentUser.uid);
        log("Added creator's ID (${currentUser.uid}) to the members list.");
      }

      if (selectedProjectId == null) {
        // Enforce project limit of 3
        if (projects.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You can only create up to 3 projects.")),
          );
          return;
        }

        // Add new project
        await FirebaseFirestore.instance.collection('projects').add({
          'name': projectName,
          'description': projectDescription,
          'createdBy': currentUser.uid,
          'members': updatedMembers, // Add creator and other members
          'creationDate': FieldValue.serverTimestamp(),
        });
        log("Project '$projectName' created successfully with members: $updatedMembers.");
      } else {
        // Update existing project
        await FirebaseFirestore.instance.collection('projects').doc(selectedProjectId).update({
          'name': projectName,
          'description': projectDescription,
          'members': updatedMembers, // Ensure creator's ID is included
          'updatedAt': FieldValue.serverTimestamp(),
        });
        log("Project '$projectName' updated successfully with members: $updatedMembers.");
      }

      _fetchProjects(); // Refresh project list
      _resetForm(); // Reset form
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project saved successfully.")),
      );
    } catch (e) {
      log("Error saving project: $e");
    }
  }

  /// Delete a project
  Future<void> _deleteProject(String projectId) async {
    try {
      await FirebaseFirestore.instance.collection('projects').doc(projectId).delete();
      log("Project '$projectId' deleted successfully.");
      _fetchProjects();
    } catch (e) {
      log("Error deleting project: $e");
    }
  }

  /// Load project data for editing
  void _loadProjectForEdit(DocumentSnapshot project) {
    setState(() {
      selectedProjectId = project.id;
      projectNameController.text = project['name'];
      projectDescriptionController.text = project['description'];
      selectedMembers = List<String>.from(project['members'] ?? []);
    });
    log("Loaded project '${project['name']}' for editing.");
  }

  /// Reset the form fields
  void _resetForm() {
    setState(() {
      selectedProjectId = null;
      projectNameController.clear();
      projectDescriptionController.clear();
      selectedMembers = [];
    });
    log("Form reset.");
  }

  /// Build the project list view
  Widget _buildProjectList() {
    return Column(
      children: projects.map((project) {
        return ListTile(
          title: Text(project['name']),
          subtitle: Text(project['description']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _loadProjectForEdit(project),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteProject(project.id),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build member dropdown for project assignment
  Widget _buildMemberDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Assign Members", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Add Member",
          ),
          items: users.map((user) {
            return DropdownMenuItem<String>(
              value: user['id'],
              child: Text(user['name'] ?? "Unknown User"),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && !selectedMembers.contains(value)) {
              setState(() {
                selectedMembers.add(value);
              });
              log("Added member: $value");
            }
          },
        ),
        Wrap(
          spacing: 8,
          children: selectedMembers.map((memberId) {
            final user = users.firstWhere(
                  (user) => user['id'] == memberId,
              orElse: () => {'name': "Unknown User"},
            );
            return Chip(
              label: Text(user['name'] ?? "Unknown User"),
              onDeleted: () {
                setState(() {
                  selectedMembers.remove(memberId);
                });
                log("Removed member: $memberId");
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Projects")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Projects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildProjectList(),
            const Divider(),

            // Form for create/update project
            const Text("Project Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: projectNameController,
              decoration: const InputDecoration(labelText: "Project Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: projectDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Project Description", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            _buildMemberDropdown(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProject,
                child: Text(selectedProjectId == null ? "Create Project" : "Update Project"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    projectNameController.dispose();
    projectDescriptionController.dispose();
    super.dispose();
  }
}
