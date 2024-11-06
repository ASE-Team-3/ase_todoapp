// views/home/home_view.dart
import 'package:animate_do/animate_do.dart';
import 'package:app/extensions/space_exs.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/utils/constrants.dart';
import 'package:app/views/home/components/fab.dart';
import 'package:app/views/home/components/home_app_bar.dart';
import 'package:app/views/home/components/slider_drawer.dart';
import 'package:app/views/home/widget/calendar_view.dart';
import 'package:app/views/home/widget/priority_view.dart';
import 'package:app/views/home/widget/due_date_view.dart';
import 'package:app/views/home/widget/task_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/task_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  GlobalKey<SliderDrawerState> drawerKey = GlobalKey<SliderDrawerState>();
  String selectedView = 'List'; // Default view

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: const Fab(),
      body: SliderDrawer(
        key: drawerKey,
        isDraggable: false,
        animationDuration: 1000,
        slider: CustomDrawer(),
        appBar: HomeAppBar(drawerKey: drawerKey),
        child: _buildHomeBody(textTheme, screenSize),
      ),
    );
  }

  Widget _buildHomeBody(TextTheme textTheme, Size screenSize) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          _buildHeader(textTheme),
          const Divider(thickness: 2, indent: 100),
          _buildViewSelector(),
          Expanded(child: _buildTaskListOrView(textTheme)),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View Tasks By:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Dynamically adapt padding and alignment based on screen width
              double buttonPadding = constraints.maxWidth < 400 ? 4.0 : 8.0;
              double fontSize = constraints.maxWidth < 400 ? 14.0 : 16.0;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[600],
                    selectedColor: AppColors.primaryColor,
                    fillColor: Colors.grey[200],
                    selectedBorderColor: AppColors.primaryColor,
                    borderColor: Colors.grey,
                    isSelected: [
                      selectedView == 'List',
                      selectedView == 'Due Date',
                      selectedView == 'Priority',
                      selectedView == 'Calendar',
                    ],
                    onPressed: (index) {
                      setState(() {
                        selectedView =
                            ['List', 'Due Date', 'Priority', 'Calendar'][index];
                      });
                    },
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: buttonPadding),
                        child: Text(
                          'List',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: buttonPadding),
                        child: Text(
                          'Due Date',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: buttonPadding),
                        child: Text(
                          'Priority',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: buttonPadding),
                        child: Text(
                          'Calendar',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListOrView(TextTheme textTheme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (selectedView == 'Calendar') {
          return CalendarView(tasks: taskProvider.tasks);
        } else if (selectedView == 'Priority') {
          return PriorityView(tasks: taskProvider.tasks);
        } else if (selectedView == 'Due Date') {
          return DueDateView(tasks: taskProvider.tasks);
        } else {
          return _buildTaskList(textTheme);
        }
      },
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: Provider.of<TaskProvider>(context).tasks.isNotEmpty
                  ? Provider.of<TaskProvider>(context).completedTasks /
                      Provider.of<TaskProvider>(context).tasks.length
                  : 0, // Handle empty list by setting to 0
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
            ),
          ),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStr.mainTitle, style: textTheme.headlineMedium),
              SizedBox(height: 4),
              Consumer<TaskProvider>(
                builder: (context, taskProvider, _) {
                  return Text(
                    "${taskProvider.completedTasks} of ${taskProvider.tasks.length} Tasks Completed",
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TextTheme textTheme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: taskProvider.tasks.isNotEmpty
              ? ListView.builder(
                  itemCount: taskProvider.tasks.length,
                  itemBuilder: (context, index) {
                    final task = taskProvider.tasks[index];
                    return Dismissible(
                      direction: DismissDirection.horizontal,
                      onDismissed: (_) {
                        taskProvider.removeTask(task);
                      },
                      background: _buildDismissBackground(),
                      key: Key(task.id),
                      child: TaskWidget(
                        task: task,
                        onToggleComplete: () =>
                            taskProvider.toggleTaskCompletion(task),
                      ),
                    );
                  },
                )
              : _buildEmptyState(textTheme),
        );
      },
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      color: Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(width: 8),
          Text(AppStr.deleteTask, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeIn(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(lottieURL, animate: true),
            ),
          ),
          FadeInUp(
            from: 30,
            child: Text(AppStr.doneAllTask, style: textTheme.headlineSmall),
          ),
        ],
      ),
    );
  }
}
