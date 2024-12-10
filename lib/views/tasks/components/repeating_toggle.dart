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
    return Center(
      child: SizedBox(
        width: 300, // Adjust horizontal size
        height: 50, // Adjust vertical size
        child: SwitchListTile(
          title: Text(
            "Repeat Task",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          value: isRepeating,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
