import 'package:app/providers/task_provider.dart';
import 'package:app/views/home/components/slider_drawer.dart';
import 'package:app/views/home/components/home_app_bar.dart';
import 'package:app/views/home/components/fab.dart';
import 'package:app/views/home/widget/points_view.dart';
import 'package:app/views/home/widget/calendar_view.dart';
import 'package:app/views/home/widget/priority_view.dart';
import 'package:app/views/home/widget/due_date_view.dart';
import 'package:app/views/home/widget/points_history_view.dart';
import 'package:app/views/home/widget/task_list_view.dart'; // TaskListView import
import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:provider/provider.dart';
import 'package:app/utils/app_str.dart';

class HomeView extends StatefulWidget {
  final String initialView;
  const HomeView({super.key, this.initialView = AppStr.home});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  GlobalKey<SliderDrawerState> drawerKey = GlobalKey<SliderDrawerState>();
  late String selectedView;
  String userName = "Loading..."; // Placeholder while loading user data

  final List<String> views = [
    AppStr.home,
    AppStr.list,
    AppStr.dueDate,
    AppStr.priority,
    AppStr.calendar,
    AppStr.pointsHistory,
  ];

  @override
  void initState() {
    super.initState();
    selectedView = widget.initialView;
    print("HomeView initialized with initialView: $selectedView");
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      print("Fetching user name from Firestore...");
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        print("User found: ${user.uid}");

        // Query Firestore for user data
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users') // Your Firestore collection for users
            .doc(user.uid) // Document ID is the user's UID
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data();
          setState(() {
            userName = userData?['name'] ?? "User"; // Retrieve the 'name' field
            print("User name retrieved: $userName");
          });
        } else {
          print("User document does not exist in Firestore.");
          setState(() {
            userName = "Unknown User";
          });
        }
      } else {
        print("No user is currently logged in.");
        setState(() {
          userName = "Guest";
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
      setState(() {
        userName = "Error";
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      print("Attempting to log out...");
      await FirebaseAuth.instance.signOut(); // Log out the user
      print("Logout successful. Redirecting to login screen...");
      Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
    } catch (e) {
      print("Logout failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout Failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building HomeView...");
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: const Fab(),
      body: SliderDrawer(
        key: drawerKey,
        isDraggable: false,
        slider: CustomDrawer(
          views: views,
          selectedView: selectedView,
          onViewSelected: (view) {
            print("Selected view: $view");
            setState(() {
              selectedView = view;
              drawerKey.currentState?.closeSlider();
            });
          },
          onLogout: () {
            print("Logout option selected.");
            _logout(context);
          },
          userName: userName, // Pass the dynamically fetched username
        ),
        appBar: HomeAppBar(drawerKey: drawerKey),
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    print("Building main content for selected view: $selectedView");
    final taskProvider = Provider.of<TaskProvider>(context);

    // Display the corresponding view based on the selected tab
    switch (selectedView) {
      case AppStr.calendar:
        return CalendarView(tasks: taskProvider.tasks());
      case AppStr.priority:
        return PriorityView(tasks: taskProvider.tasks());
      case AppStr.dueDate:
        return DueDateView(tasks: taskProvider.tasks());
      case AppStr.pointsHistory:
        return const PointsHistoryView();
      case AppStr.list:
        return const TaskListView(); // No need to pass tasks here anymore
      default:
        return const PointsView();
    }
  }
}
