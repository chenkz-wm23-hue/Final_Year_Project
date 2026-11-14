import 'dart:async';

import '../data/repositories/expense_repository.dart';
import '../data/models/transaction.dart';
import 'expense_validation.dart';

class TransactionManagement {
  final ExpenseRepository repository;
  const TransactionManagement(this.repository);
  void requireIncome(DateTime date, {int? excludingId}) {
    if (!repository.transactions.any(
      (entry) =>
          entry.id != excludingId &&
          entry.income &&
          entry.amount > 0 &&
          entry.date.year == date.year &&
          entry.date.month == date.month,
    )) {
      throw const ExpenseValidationException();
    }
  }

  List<TransactionEntry> forMonth(DateTime month) =>
      repository.transactions
          .where(
            (e) => e.date.year == month.year && e.date.month == month.month,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  FutureOr<void> save({
    int? id,
    required String description,
    required double amount,
    required DateTime date,
    required String category,
    required bool income,
    String? receiptPath,
    String? merchant,
  }) {
    if (description.trim().isEmpty || !amount.isFinite || amount <= 0) {
      throw ArgumentError('Enter a description and positive amount.');
    }
    if (!income) requireIncome(date, excludingId: id);
    final previous = repository.transactions
        .where((entry) => entry.id == id)
        .firstOrNull;
    return repository.upsertTransaction(
      TransactionEntry(
        id: id ?? repository.nextTransactionId(),
        description: description.trim(),
        category: category,
        amount: amount,
        date: date,
        income: income,
        receiptPath: receiptPath ?? previous?.receiptPath,
        merchant: merchant ?? previous?.merchant,
      ),
    );
  }

  FutureOr<void> delete(int id) => repository.deleteTransaction(id);
}
