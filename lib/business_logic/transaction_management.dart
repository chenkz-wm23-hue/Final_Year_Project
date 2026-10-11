import '../data/repositories/expense_repository.dart';
import '../data/models/transaction.dart';

class TransactionManagement {
  final ExpenseRepository repository;
  const TransactionManagement(this.repository);
  List<TransactionEntry> forMonth(DateTime month) =>
      repository.transactions
          .where(
            (e) => e.date.year == month.year && e.date.month == month.month,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  void save({
    int? id,
    required String description,
    required double amount,
    required DateTime date,
    required String category,
    required bool income,
  }) {
    if (description.trim().isEmpty || !amount.isFinite || amount <= 0) {
      throw ArgumentError('Enter a description and positive amount.');
    }
    repository.upsertTransaction(
      TransactionEntry(
        id: id ?? repository.nextTransactionId(),
        description: description.trim(),
        category: category,
        amount: amount,
        date: date,
        income: income,
      ),
    );
  }

  void delete(int id) => repository.deleteTransaction(id);
}
