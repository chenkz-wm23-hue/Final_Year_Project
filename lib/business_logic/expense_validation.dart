class ExpenseValidationException implements Exception {
  const ExpenseValidationException();
  static const message = 'Add income for this month before saving an expense.';
  @override
  String toString() => message;
}
