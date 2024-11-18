import 'package:flutter/material.dart';

class FlexibleDeadlineDropdown extends StatelessWidget {
  final String? flexibleDeadline;
  final ValueChanged<String?> onChanged;

  const FlexibleDeadlineDropdown({
    super.key,
    required this.flexibleDeadline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
          horizontal: 16), // Consistent with RepTextField
      child: ListTile(
        title: DropdownButtonFormField<String>(
          value: flexibleDeadline,
          decoration: InputDecoration(
            hintText: "Select Flexible Deadline",
            hintStyle: const TextStyle(color: Colors.grey), // Optional styling
            prefixIcon: const Icon(Icons.date_range,
                color: Colors.grey), // Icon similar to RepTextField
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: "Today",
              child: Text(
                "Today",
                style: const TextStyle(color: Colors.black),
              ),
            ),
            DropdownMenuItem(
              value: "This Week",
              child: Text(
                "This Week",
                style: const TextStyle(color: Colors.black),
              ),
            ),
            DropdownMenuItem(
              value: "No Deadline",
              child: Text(
                "No Deadline",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
          onChanged: onChanged,
          isExpanded: true, // Ensures it spans full width
        ),
      ),
    );
  }
}
