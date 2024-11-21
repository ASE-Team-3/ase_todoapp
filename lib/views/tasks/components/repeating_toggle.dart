// views\tasks\components\repeating_toggle.dart
import 'package:flutter/material.dart';

class RepeatingToggle extends StatelessWidget {
  final bool isRepeating;
  final ValueChanged<bool> onChanged;

  const RepeatingToggle({
    super.key,
    required this.isRepeating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        "Repeat Task",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      value: isRepeating,
      onChanged: onChanged,
    );
  }
}
