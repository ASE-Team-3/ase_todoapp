/// A centralized list of task categories for reuse throughout the app.
class TaskCategories {
  static const List<String> categories = [
    "General",
    "Research",
    "Work",
    "Personal",
    "Health",
    "Finance",
  ];

  /// Function to validate a category (optional, for stricter control)
  static bool isValidCategory(String category) {
    return categories.contains(category);
  }
}
