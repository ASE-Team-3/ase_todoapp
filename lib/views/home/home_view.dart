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
  final List<int> testing = [];
  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,

      // FAB
      floatingActionButton: Fab(),

      // Body
      body: SliderDrawer(
        key: drawerKey,
        isDraggable: false,
        animationDuration: 1000,

        // Drawer
        slider: CustomDrawer(),

        appBar: HomeAppBar(
          drawerKey: drawerKey,
        ),

        // Main Body
        child: _buildHomeBody(textTheme),
      ),
    );
  }

  // Home Body
  SizedBox _buildHomeBody(TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          // Custom App bar
          Container(
            margin: const EdgeInsets.only(top: 60),
            width: double.infinity,
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Progress Indicator
                SizedBox(
                  width: 30,
                  height: 30,
                  child: const CircularProgressIndicator(
                    value: 1 / 3,
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                  ),
                ),

                25.w,

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStr.mainTitle,
                      style: textTheme.displayLarge,
                    ),
                    3.h,
                    Text(
                      "1 of 3 Task",
                      style: textTheme.titleMedium,
                    )
                  ],
                )
              ],
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Divider(
              thickness: 2,
              indent: 100,
            ),
          ),

          //Tasks
          SizedBox(
            width: double.infinity,
            height: 745,
            child: testing.isNotEmpty

                // Task list is not empty
                ? ListView.builder(
                    itemCount: testing.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      return Dismissible(
                          direction: DismissDirection.horizontal,
                          onDismissed: (_) {
                            // We will remove current task from DB
                          },
                          background: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              8.w,
                              const Text(
                                AppStr.deleteTask,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              )
                            ],
                          ),
                          key: Key(
                            index.toString(),
                          ),
                          child: const TaskWidget());
                    })
                // Task list is empty
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeIn(
                        child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Lottie.asset(lottieURL,
                                animate: testing.isNotEmpty ? false : true)),
                      ),
                      FadeInUp(
                        from: 30,
                        child: const Text(
                          AppStr.doneAllTask,
                        ),
                      )
                    ],
                  ),
          )
        ],
      ),
    );
  }
}
