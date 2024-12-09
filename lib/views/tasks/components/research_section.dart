import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/utils/app_colors.dart';

class ResearchSection extends StatelessWidget {
  final List<String> keywords;
  final ValueChanged<String> onAddKeyword;
  final ValueChanged<String> onRemoveKeyword;
  final VoidCallback onGenerateKeywords; // Generate system keywords
  final VoidCallback onRefreshSuggestions; // Refresh research suggestions
  final String? suggestedPaper;
  final String? suggestedPaperUrl;

  const ResearchSection({
    super.key,
    required this.keywords,
    required this.onAddKeyword,
    required this.onRemoveKeyword,
    required this.onGenerateKeywords,
    required this.onRefreshSuggestions,
    this.suggestedPaper,
    this.suggestedPaperUrl,
  });

  @override
  Widget build(BuildContext context) {
    final keywordController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keywords Input Area
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56, // Matches the height of other dropdowns
                child: TextField(
                  controller: keywordController,
                  decoration: InputDecoration(
                    labelText: "Add a Keyword",
                    floatingLabelBehavior: FloatingLabelBehavior.auto, // Enables floating label animation
                    labelStyle: MaterialStateTextStyle.resolveWith((states) {
                      if (states.contains(MaterialState.focused)) {
                        return const TextStyle(
                          color: Colors.black, // Black when focused
                          fontWeight: FontWeight.bold, // Bold when focused
                        );
                      }
                      return TextStyle(color: Colors.grey.shade600); // Grey when idle
                    }),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: MaterialStateColor.resolveWith((states) {
                      if (states.contains(MaterialState.focused)) {
                        return Colors.white; // White when focused
                      }
                      return Colors.grey.shade100; // Light grey when idle
                    }),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56, // Matches the height of other dropdowns
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (keywordController.text.trim().isNotEmpty) {
                    onAddKeyword(keywordController.text.trim());
                    keywordController.clear();
                  }
                },
                child: const Text("Add"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Generate Keywords Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onGenerateKeywords,
          icon: const Icon(Icons.auto_fix_high),
          label: const Text("Generate Keywords"),
        ),
        const SizedBox(height: 16),

        // List of Keyword Chips
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: keywords
              .map((keyword) => Chip(
            label: Text(
              keyword,
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            deleteIconColor: Colors.red,
            onDeleted: () => onRemoveKeyword(keyword),
          ))
              .toList(),
        ),
        const SizedBox(height: 16),

        // Suggested Research Work Card
        if (suggestedPaper != null)
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                suggestedPaper!,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text("Tap to view the full research paper."),
              trailing: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                onPressed: onRefreshSuggestions,
              ),
              onTap: () {
                if (suggestedPaperUrl != null) {
                  launchUrl(Uri.parse(suggestedPaperUrl!));
                }
              },
            ),
          )
        else
          Center(
            child: Column(
              children: [
                const Text(
                  "No research suggestion available.",
                  style: TextStyle(color: Colors.black54),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onRefreshSuggestions,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Suggestions"),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
