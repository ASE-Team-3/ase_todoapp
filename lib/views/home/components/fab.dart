import 'dart:developer';

import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class Fab extends StatefulWidget {
  const Fab({super.key});

  @override
  State<Fab> createState() => _FabState();
}

class _FabState extends State<Fab> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          log("Task view");
        },
        child: Material(
          borderRadius: BorderRadius.circular(15),
          elevation: 10,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(15)),
            child: const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ));
  }
}
