import '../data/models/transaction.dart';

class DashboardSummary {
  final double income, expense, budget;
  final Map<String, double> categoryTotals;
  const DashboardSummary({
    required this.income,
    required this.expense,
    required this.budget,
    required this.categoryTotals,
  });
  double get balance => income - expense;
  double get remaining => budget - expense;
  double get ratio => expense / budget;
}

class DashboardCalculation {
  const DashboardCalculation();
  DashboardSummary calculate(List<TransactionEntry> entries, double budget) {
    double income = 0, expense = 0;
    final categories = <String, double>{};
    for (final entry in entries) {
      if (entry.income) {
        income += entry.amount;
      } else {
        expense += entry.amount;
        categories[entry.category] =
            (categories[entry.category] ?? 0) + entry.amount;
      }
    }
    return DashboardSummary(
      income: income,
      expense: expense,
      budget: budget,
      categoryTotals: Map.unmodifiable(categories),
    );
  }
}
