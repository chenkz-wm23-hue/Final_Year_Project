import '../models/transaction.dart';
import '../models/user.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/keyword.dart';

/// Local repository contract. A future remote adapter may use an asynchronous API.
abstract class ExpenseRepository {
  List<TransactionEntry> get transactions;
  void upsertTransaction(TransactionEntry entry);
  void deleteTransaction(int id);
  int nextTransactionId();
  MonthlyBudget? budgetFor(DateTime month);
  void saveBudget(MonthlyBudget budget);
  UserProfile get user;
  void saveUser(UserProfile profile);
  List<Category> get categories;
  List<CategoryKeyword> get keywords;
}
