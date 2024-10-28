import 'package:flutter/material.dart';

class DateTimeSelectionWidget extends StatelessWidget {
  const DateTimeSelectionWidget({
    super.key,
    required this.onTap,
    required this.title,
  });

  final VoidCallback onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding:
            const EdgeInsets.symmetric(vertical: 12), // Added vertical padding
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius:
              BorderRadius.circular(12), // Slightly adjusted border radius
          boxShadow: [
            BoxShadow(
              color: Colors.grey
                  .withOpacity(0.1), // Softer shadow for a subtle effect
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold), // Emphasized title
              ),
            ),
            // Placeholder for future elements or interactions
            const Icon(Icons.arrow_forward,
                color: Colors.grey), // Added an arrow icon for better UX
          ],
        ),
      ),
    );
  }
}
