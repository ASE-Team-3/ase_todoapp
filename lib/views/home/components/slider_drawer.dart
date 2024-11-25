import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final List<String> views;
  final String selectedView;
  final Function(String) onViewSelected;

  /// Static Icons and Texts
  static const List<IconData> icons = [
    CupertinoIcons.settings,
    CupertinoIcons.info_circle_fill,
  ];

  static const List<String> texts = [
    AppStr.settings,
    AppStr.details,
  ];

  const CustomDrawer({
    required this.views,
    required this.selectedView,
    required this.onViewSelected,
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
            "NAME",
            style: textTheme.displayMedium,
          ),
          Text(
            "Flutter Dev",
            style: textTheme.displaySmall,
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
        return Icons.home; // Default icon for Home
    }
  }

  /// Handle navigation for static views
  void _handleStaticViewSelected(BuildContext context, String view) {
    if (view == "Settings") {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const _SettingsView(), // TODO: Implement this view
        ),
      );
    } else if (view == "Details") {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const _DetailsView(), // TODO: Implement this view
        ),
      );
    }
  }
}

/// Placeholder for Settings View
class _SettingsView extends StatelessWidget {
  const _SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: const Center(
        child: Text(
          "Settings View - TODO: Implement",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Placeholder for Details View
class _DetailsView extends StatelessWidget {
  const _DetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: const Center(
        child: Text(
          "Details View - TODO: Implement",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
