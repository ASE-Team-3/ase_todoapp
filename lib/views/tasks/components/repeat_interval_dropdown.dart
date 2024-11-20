// views/tasks/components/repeat_interval_dropdown.dart
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
    return DropdownButtonFormField<String>(
      value: repeatInterval,
      decoration: InputDecoration(
        labelText: "Repeat Interval",
        hintText: "Select Repeat Interval",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        DropdownMenuItem(value: "daily", child: Text("Daily")),
        DropdownMenuItem(value: "weekly", child: Text("Weekly")),
        DropdownMenuItem(value: "monthly", child: Text("Monthly")),
        DropdownMenuItem(value: "yearly", child: Text("Yearly")),
        DropdownMenuItem(value: "custom", child: Text("Custom Interval")),
      ],
      onChanged: onChanged,
    );
  }
}
