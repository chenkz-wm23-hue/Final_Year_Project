class MonthlyBudget {
  final int year, month;
  final double amount;
  const MonthlyBudget({
    required this.year,
    required this.month,
    required this.amount,
  });
  String get key => '$year-$month';
}
