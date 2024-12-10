import 'package:flutter/material.dart';
import 'package:app/utils/deadline_utils.dart'; // Import deadline utils

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
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white, // Sets the entire dropdown background to white
            ),
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
                  ...predefinedDeadlines.keys.map(
                        (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: const TextStyle(color: Colors.black), // Black text
                      ),
                    ),
                  ),
                  const DropdownMenuItem<String>(
                    value: "Specific Deadline",
                    child: Text(
                      "Specific Deadline",
                      style: TextStyle(color: Colors.black), // Black text
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    widget.onFlexibleDeadlineChanged(value);
                    if (value == "Specific Deadline") {
                      // Reset previous values and show specific deadline picker
                      selectedSpecificDeadline = null;
                      widget.onSpecificDeadlineSelected(null);
                    } else {
                      // Calculate a flexible deadline if it's a predefined option
                      selectedSpecificDeadline =
                          calculateDeadlineFromFlexible(value!);
                      widget.onSpecificDeadlineSelected(
                          selectedSpecificDeadline);
                    }
                  });
                },
                isExpanded: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
