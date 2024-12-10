import 'package:flutter/material.dart';
import 'package:app/constants/task_categories.dart';
import 'package:app/utils/app_colors.dart';

class CategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal:20),
      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10000,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedCategory,
        onChanged: onCategoryChanged,
        decoration: InputDecoration(
          labelText: "Task Category",
          labelStyle: const TextStyle(
            color: Colors.black, // Light grey color
            fontWeight: FontWeight.bold,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade500), // Light grey border
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade500, width: 2), // Light grey border

          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade500), // Light grey border
          ),

        ),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.black),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        items: TaskCategories.categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(
              category,
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }).toList(),
      ),
    );
  }
}
