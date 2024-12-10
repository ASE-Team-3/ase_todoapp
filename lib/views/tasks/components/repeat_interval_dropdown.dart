import 'package:flutter/material.dart';

class RepeatIntervalDropdown extends StatelessWidget {
  final String? repeatInterval;
  final ValueChanged<String?> onChanged;

  const RepeatIntervalDropdown({
    super.key,
    required this.repeatInterval,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 335, // Adjust horizontal size
        height: 60, // Adjust vertical size
        child: DropdownButtonFormField<String>(
          value: repeatInterval,
          decoration: InputDecoration(
            labelText: "Repeat Interval",
            hintText: "Select Repeat Interval",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          dropdownColor: Colors.white, // Background of the dropdown menu
          style: const TextStyle(
            color: Colors.grey, // Text color of dropdown items
            fontWeight: FontWeight.w600, // Slightly bold text
          ),
          items: const [
            DropdownMenuItem(
              value: "daily",
              child: Text("Daily"),
            ),
            DropdownMenuItem(
              value: "weekly",
              child: Text("Weekly"),
            ),
            DropdownMenuItem(
              value: "monthly",
              child: Text("Monthly"),
            ),
            DropdownMenuItem(
              value: "yearly",
              child: Text("Yearly"),
            ),
            DropdownMenuItem(
              value: "custom",
              child: Text("Custom Interval"),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
