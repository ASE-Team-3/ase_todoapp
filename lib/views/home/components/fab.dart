import 'package:app/services/research_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/views/tasks/task_create_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Fab extends StatelessWidget {
  const Fab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Access ResearchService from the provider
        final researchService =
            Provider.of<ResearchService>(context, listen: false);

        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => TaskCreateView(
              researchService: researchService,
            ),
          ),
        );
      },
      child: Material(
        borderRadius: BorderRadius.circular(15),
        elevation: 10,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
