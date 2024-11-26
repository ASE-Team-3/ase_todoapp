Map<String, dynamic>? validateCustomReminder(Map<String, dynamic>? reminder) {
  if (reminder == null ||
      reminder['quantity'] == null ||
      reminder['unit'] == null) {
    return null;
  }

  final quantity = reminder['quantity'];
  final unit = reminder['unit'];

  if (quantity <= 0 || (unit != "hours" && unit != "days" && unit != "weeks")) {
    return null; // Invalid custom reminder
  }

  return reminder;
}
