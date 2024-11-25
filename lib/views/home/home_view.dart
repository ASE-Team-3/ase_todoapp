import 'package:app/providers/task_provider.dart';
import 'package:app/views/home/components/slider_drawer.dart';
import 'package:app/views/home/components/home_app_bar.dart';
import 'package:app/views/home/components/fab.dart';
import 'package:app/views/home/widget/points_view.dart';
import 'package:app/views/home/widget/calendar_view.dart';
import 'package:app/views/home/widget/priority_view.dart';
import 'package:app/views/home/widget/due_date_view.dart';
import 'package:app/views/home/widget/points_history_view.dart';
import 'package:app/views/home/widget/task_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
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
  }

  @override
  Widget build(BuildContext context) {
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
            setState(() {
              selectedView = view;
              drawerKey.currentState?.closeSlider();
            });
          },
        ),
        appBar: HomeAppBar(drawerKey: drawerKey),
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    final taskProvider = Provider.of<TaskProvider>(context);

    switch (selectedView) {
      case AppStr.calendar:
        return CalendarView(tasks: taskProvider.tasks);
      case AppStr.priority:
        return PriorityView(tasks: taskProvider.tasks);
      case AppStr.dueDate:
        return DueDateView(tasks: taskProvider.tasks);
      case AppStr.pointsHistory:
        return const PointsHistoryView();
      case AppStr.list:
        return TaskListView(tasks: taskProvider.tasks);
      default:
        return const PointsView();
    }
  }
}
