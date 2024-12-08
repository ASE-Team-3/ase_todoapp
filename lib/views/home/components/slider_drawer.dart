import 'package:app/views/home/settings_page.dart'; // Ensure this is the path to your settings_page.dart file
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';

class CustomDrawer extends StatelessWidget {
  final List<String> views;
  final String selectedView;
  final Function(String) onViewSelected;
  final VoidCallback? onLogout;
  final String userName; // Added userName parameter

  /// Static Icons and Texts
  static const List<IconData> icons = [
    CupertinoIcons.settings,
    CupertinoIcons.info_circle_fill,
    Icons.logout, // Added logout icon
  ];

  static const List<String> texts = [
    AppStr.settings,
    AppStr.details,
    "Logout", // Added logout text
  ];

  const CustomDrawer({
    required this.views,
    required this.selectedView,
    required this.onViewSelected,
    required this.userName,
    this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradientColor,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // User Profile Section
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              "https://avatars.githubusercontent.com/u/91388754?v=4",
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: textTheme.displayMedium,
          ),
          const SizedBox(height: 30),
          // Dynamic List Section
          Expanded(
            child: ListView(
              children: [
                _buildDynamicList(),
                const Divider(color: Colors.white70, thickness: 1),
                _buildStaticList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dynamic list section for views
  Widget _buildDynamicList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: views.length,
      itemBuilder: (context, index) {
        final view = views[index];
        return ListTile(
          title: Text(
            view,
            style: TextStyle(
              color: selectedView == view ? Colors.black : Colors.white,
              fontWeight:
              selectedView == view ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          leading: Icon(
            _getIconForView(view),
            color: selectedView == view ? Colors.black : Colors.white,
          ),
          onTap: () => onViewSelected(view),
        );
      },
    );
  }

  /// Builds the static items section
  Widget _buildStaticList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: Icon(
            icons[index],
            color: selectedView == texts[index] ? Colors.black : Colors.white,
          ),
          title: Text(
            texts[index],
            style: TextStyle(
              color: selectedView == texts[index] ? Colors.black : Colors.white,
              fontWeight: selectedView == texts[index]
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          onTap: () => _handleStaticViewSelected(context, texts[index]),
        );
      },
    );
  }

  /// Retrieves the appropriate icon for a dynamic view
  IconData _getIconForView(String view) {
    switch (view) {
      case AppStr.calendar:
        return Icons.calendar_today;
      case AppStr.priority:
        return Icons.priority_high;
      case AppStr.dueDate:
        return Icons.date_range;
      case AppStr.pointsHistory:
        return Icons.bar_chart;
      case AppStr.list:
        return Icons.list;
      default:
        return Icons.home;
    }
  }

  /// Handle navigation for static views
  void _handleStaticViewSelected(BuildContext context, String view) {
    if (view == AppStr.settings) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsPageState(), // Direct to the actual SettingsPage
        ),
      );
    } else if (view == AppStr.details) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetailsView(viewTitle: view), // Dynamic DetailsView
        ),
      );
    } else if (view == "Logout") {
      if (onLogout != null) {
        onLogout!();
      } else {
        _logout(context);
      }
    }
  }

  /// Default Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout Failed: ${e.toString()}')),
      );
    }
  }
}

/// Dynamic DetailsView implementation
class DetailsView extends StatelessWidget {
  final String viewTitle;

  const DetailsView({required this.viewTitle, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viewTitle),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text('Details for: $viewTitle'),
      ),
    );
  }
}
