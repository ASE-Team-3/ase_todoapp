import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _newProjectController = TextEditingController();

  late String _userId;
  String _email = '';
  List<String> _projects = [];
  String _emailQueryResult = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _queryByEmail();
  }

  Future<void> _loadUserData() async {
    try {
      // Get the current user's ID and email
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
        _email = user.email ?? '';

        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          setState(() {
            _nameController.text = data['name'] ?? ''; // Populate name
            _projects = List<String>.from(data['projects'] ?? []); // Populate projects
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: ${e.toString()}')),
      );
    }
  }

  Future<void> _queryByEmail() async {
    try {
      if (_email.isEmpty) {
        setState(() {
          _emailQueryResult = 'No email available for the user.';
        });
        return;
      }

      // Query Firestore for users with the current email
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        print('Query Result for $_email: $userData');
        setState(() {
          _emailQueryResult = 'User Data for $_email: $userData';
        });
      } else {
        print('No user found with email $_email.');
        setState(() {
          _emailQueryResult = 'No user found with email $_email.';
        });
      }
    } catch (e) {
      print('Failed to query by email: $e');
      setState(() {
        _emailQueryResult = 'Failed to query by email: ${e.toString()}';
      });
    }
  }

  Future<void> _updateName() async {
    try {
      // Update the user's name in Firestore
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'name': _nameController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: ${e.toString()}')),
      );
    }
  }

  Future<void> _addProject() async {
    try {
      String newProject = _newProjectController.text.trim();

      if (newProject.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project name cannot be empty.')),
        );
        return;
      }

      // Add the new project to the Firestore `projects` array
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'projects': FieldValue.arrayUnion([newProject]),
      });

      setState(() {
        _projects.add(newProject); // Update local state
        _newProjectController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add project: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _updateName,
                child: const Text('Update Name'),
              ),
              const Divider(height: 30),
              const Text(
                'Existing Projects',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildProjectsList(),
              const Divider(height: 30),
              const Text(
                'Add New Project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newProjectController,
                decoration: const InputDecoration(labelText: 'New Project Name'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addProject,
                child: const Text('Add Project'),
              ),
              const Divider(height: 30),
              const Text(
                'Email Query Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(_emailQueryResult),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the list of existing projects
  Widget _buildProjectsList() {
    if (_projects.isEmpty) {
      return const Text('No projects found.');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_projects[index]),
        );
      },
    );
  }
}
