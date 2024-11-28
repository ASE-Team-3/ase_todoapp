import 'package:flutter/material.dart';
import 'package:app/constants/task_categories.dart';

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
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      onChanged: onCategoryChanged,
      decoration: InputDecoration(
        labelText: "Task Category",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: TaskCategories.categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
    );
  }
}
