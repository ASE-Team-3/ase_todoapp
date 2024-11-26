import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/utils/app_str.dart';

class CustomReminderInput extends StatelessWidget {
  final Map<String, dynamic>? customReminder;
  final Function(Map<String, dynamic>?) onCustomReminderChanged;

  const CustomReminderInput({
    super.key,
    required this.customReminder,
    required this.onCustomReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStr.customReminderLabel, // "Set Custom Reminder"
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: AppStr.customReminderQuantityLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    final updatedReminder = Map<String, dynamic>.from(
                        customReminder ?? {"quantity": 0, "unit": "hours"});
                    updatedReminder['quantity'] = int.tryParse(value) ?? 0;
                    onCustomReminderChanged(updatedReminder);
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: customReminder?['unit'] ?? "hours",
                items: const [
                  DropdownMenuItem(
                    value: "hours",
                    child: Text(AppStr.hours),
                  ),
                  DropdownMenuItem(
                    value: "days",
                    child: Text(AppStr.days),
                  ),
                  DropdownMenuItem(
                    value: "weeks",
                    child: Text(AppStr.weeks),
                  ),
                ],
                onChanged: (value) {
                  final updatedReminder = Map<String, dynamic>.from(
                      customReminder ?? {"quantity": 0, "unit": "hours"});
                  updatedReminder['unit'] = value ?? "hours";
                  onCustomReminderChanged(updatedReminder);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
