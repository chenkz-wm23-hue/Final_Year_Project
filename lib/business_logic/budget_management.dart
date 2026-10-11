import '../data/models/budget.dart';
import '../data/repositories/expense_repository.dart';

class BudgetManagement {
  final ExpenseRepository repository;
  const BudgetManagement(this.repository);
  double amountFor(DateTime month) =>
      repository.budgetFor(month)?.amount ?? 1500;
  void save(DateTime month, double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Budget must be positive.');
    }
    repository.saveBudget(
      MonthlyBudget(year: month.year, month: month.month, amount: amount),
    );
  }
}
