// views\tasks\components\custom_interval_input.dart
import 'package:flutter/material.dart';

class CustomIntervalInput extends StatelessWidget {
  final int? customRepeatDays;
  final ValueChanged<int?> onChanged;

  const CustomIntervalInput({
    super.key,
    required this.customRepeatDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: "Custom Interval (Days)",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        onChanged(int.tryParse(value));
      },
    );
  }
}
