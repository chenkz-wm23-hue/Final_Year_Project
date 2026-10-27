import 'dart:async';

import '../models/transaction.dart';
import '../models/user.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/keyword.dart';

/// Cached reads with asynchronous-capable writes. Remote implementations load before use.
abstract class ExpenseRepository {
  List<TransactionEntry> get transactions;
  FutureOr<void> upsertTransaction(TransactionEntry entry);
  FutureOr<void> deleteTransaction(int id);
  int nextTransactionId();
  MonthlyBudget? budgetFor(DateTime month);
  FutureOr<void> saveBudget(MonthlyBudget budget);
  UserProfile get user;
  FutureOr<void> saveUser(UserProfile profile);
  List<Category> get categories;
  List<CategoryKeyword> get keywords;
}
