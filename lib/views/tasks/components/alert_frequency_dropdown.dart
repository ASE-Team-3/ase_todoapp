import 'package:flutter/material.dart';
import 'package:app/utils/app_str.dart';

class AlertFrequencyDropdown extends StatelessWidget {
  final String? alertFrequency;
  final Function(String? value) onFrequencyChanged;

  const AlertFrequencyDropdown({
    Key? key,
    required this.alertFrequency,
    required this.onFrequencyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStr.alertFrequencyLabel, // "Alert Frequency"
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: alertFrequency ?? "5_minutes",
            items: [
              DropdownMenuItem(
                value: "5_minutes",
                child: Text(
                  AppStr.alertFrequency5Minutes,
                  style: TextStyle(
                    color: Colors.grey.shade500, // Lighter grey
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
              DropdownMenuItem(
                value: "1_hour",
                child: Text(
                  AppStr.alertFrequency1Hour,
                  style: TextStyle(
                    color: Colors.grey.shade500, // Lighter grey
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
              DropdownMenuItem(
                value: "2_hours",
                child: Text(
                  AppStr.alertFrequency2Hours,
                  style: TextStyle(
                    color: Colors.grey.shade500, // Lighter grey
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
              DropdownMenuItem(
                value: "3_hours",
                child: Text(
                  AppStr.alertFrequency3Hours,
                  style: TextStyle(
                    color: Colors.grey.shade500, // Lighter grey
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
              DropdownMenuItem(
                value: "1_day",
                child: Text(
                  AppStr.alertFrequency1Day,
                  style: TextStyle(
                    color: Colors.grey.shade500, // Lighter grey
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
              DropdownMenuItem(
                value: "custom",
                child: Text(
                  AppStr.alertFrequencyCustom,
                  style: TextStyle(
                    color: Colors.grey.shade500, // Lighter grey
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
            ],
            onChanged: onFrequencyChanged,
            dropdownColor: Colors.white, // Dropdown menu background color
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
