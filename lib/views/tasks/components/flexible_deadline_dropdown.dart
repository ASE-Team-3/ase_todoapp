import 'package:flutter/material.dart';

class FlexibleDeadlineDropdown extends StatefulWidget {
  final String? flexibleDeadline;
  final ValueChanged<DateTime?> onSpecificDeadlineSelected;
  final ValueChanged<String?> onFlexibleDeadlineChanged;

  const FlexibleDeadlineDropdown({
    super.key,
    required this.flexibleDeadline,
    required this.onSpecificDeadlineSelected,
    required this.onFlexibleDeadlineChanged,
  });

  @override
  State<FlexibleDeadlineDropdown> createState() =>
      _FlexibleDeadlineDropdownState();
}

class _FlexibleDeadlineDropdownState extends State<FlexibleDeadlineDropdown> {
  DateTime? selectedSpecificDeadline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListTile(
            title: DropdownButtonFormField<String>(
              value: widget.flexibleDeadline,
              decoration: InputDecoration(
                hintText: "Select Deadline",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.date_range, color: Colors.grey),
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
                  child: const Text(
                    "Today",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DropdownMenuItem(
                  value: "This Week",
                  child: const Text(
                    "This Week",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                DropdownMenuItem(
                  value: "Specific Deadline",
                  child: const Text(
                    "Specific Deadline",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  widget.onFlexibleDeadlineChanged(value);
                  if (value != "Specific Deadline") {
                    selectedSpecificDeadline = null; // Reset specific deadline
                    widget.onSpecificDeadlineSelected(null);
                  }
                });
              },
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }
}
