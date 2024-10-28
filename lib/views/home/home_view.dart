import 'package:animate_do/animate_do.dart';
import 'package:app/extensions/space_exs.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_str.dart';
import 'package:app/utils/constrants.dart';
import 'package:app/views/home/components/fab.dart';
import 'package:app/views/home/components/home_app_bar.dart';
import 'package:app/views/home/components/slider_drawer.dart';
import 'package:app/views/home/widget/task_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:lottie/lottie.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  GlobalKey<SliderDrawerState> drawerKey = GlobalKey<SliderDrawerState>();
  final List<int> testing = [1, 2];

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Fab(),
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

  SizedBox _buildHomeBody(TextTheme textTheme, Size screenSize) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          _buildHeader(textTheme),
          const Divider(thickness: 2, indent: 100),
          Expanded(child: _buildTaskList(textTheme)),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  value: 1 / 3,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                ),
              ),
              25.w,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStr.mainTitle, style: textTheme.displayLarge),
                  3.h,
                  Text("1 of 3 Task", style: textTheme.titleMedium),
                ],
              ),
            ],
          ),
          // You can add more widgets to the header if needed.
        ],
      ),
    );
  }

  Widget _buildTaskList(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: testing.isNotEmpty
          ? ListView.builder(
              itemCount: testing.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    // Handle task removal from DB here
                  },
                  background: _buildDismissBackground(),
                  key: Key(index.toString()),
                  child: const TaskWidget(),
                );
              },
            )
          : _buildEmptyState(textTheme),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      color: Colors.red,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
