import 'dart:typed_data';

import 'receipt_repository.dart';
import 'expense_repository.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/keyword.dart';

class InMemoryExpenseRepository
    implements ExpenseRepository, ReceiptRepository {
  InMemoryExpenseRepository() {
    final now = DateTime.now();
    _transactions.addAll([
      TransactionEntry(
        id: 1,
        description: 'Part-time salary',
        category: 'Salary',
        amount: 1500,
        date: now,
        income: true,
      ),
      TransactionEntry(
        id: 2,
        description: 'Monthly allowance',
        category: 'Allowance',
        amount: 1000,
        date: now,
        income: true,
      ),
      TransactionEntry(
        id: 3,
        description: 'KFC Dinner',
        category: 'Food',
        amount: 15,
        date: now,
        income: false,
      ),
      TransactionEntry(
        id: 4,
        description: 'Grab',
        category: 'Transport',
        amount: 12,
        date: now,
        income: false,
      ),
    ]);
  }
  final _receipts = <String, Uint8List>{};
  @override
  Future<String> uploadReceipt(String key, Uint8List png) async {
    _receipts[key] = Uint8List.fromList(png);
    return key;
  }

  @override
  Future<Uint8List> downloadReceipt(String path) async {
    final bytes = _receipts[path];
    if (bytes == null) throw StateError('Receipt unavailable');
    return Uint8List.fromList(bytes);
  }

  @override
  Future<List<TransactionEntry>> receiptCandidates(
    DateTime date,
    double amount,
  ) async => transactions;
  final _transactions = <TransactionEntry>[];
  final _budgets = <String, MonthlyBudget>{};
  var _nextId = 5;
  var _user = const UserProfile(
    name: 'Alex Tan',
    email: 'alex.tan@example.com',
  );
  @override
  List<TransactionEntry> get transactions => List.unmodifiable(_transactions);
  @override
  int nextTransactionId() => _nextId++;
  @override
  void upsertTransaction(TransactionEntry entry) {
    final i = _transactions.indexWhere(
      (e) =>
          e.id == entry.id ||
          (entry.receiptPath != null && e.receiptPath == entry.receiptPath),
    );
    if (i < 0) {
      _transactions.add(entry);
    } else {
      _transactions[i] = entry;
    }
  }

  @override
  void deleteTransaction(int id) =>
      _transactions.removeWhere((e) => e.id == id);
  @override
  MonthlyBudget? budgetFor(DateTime month) =>
      _budgets['${month.year}-${month.month}'];
  @override
  void saveBudget(MonthlyBudget budget) => _budgets[budget.key] = budget;
  @override
  UserProfile get user => _user;
  @override
  void saveUser(UserProfile profile) => _user = profile;
  @override
  List<Category> get categories => [
    for (final name in expenseCategories) Category(name),
    for (final name in incomeCategories) Category(name, income: true),
  ];
  @override
  List<CategoryKeyword> get keywords => const [
    CategoryKeyword('kfc', 'Food'),
    CategoryKeyword('mcdonald', 'Food'),
    CategoryKeyword('starbucks', 'Food'),
    CategoryKeyword('dinner', 'Food'),
    CategoryKeyword('lunch', 'Food'),
    CategoryKeyword('food', 'Food'),
    CategoryKeyword('grab', 'Transport'),
    CategoryKeyword('rapidkl', 'Transport'),
    CategoryKeyword('train', 'Transport'),
    CategoryKeyword('bus', 'Transport'),
    CategoryKeyword('shell', 'Fuel'),
    CategoryKeyword('petronas', 'Fuel'),
    CategoryKeyword('fuel', 'Fuel'),
    CategoryKeyword('shopee', 'Shopping'),
    CategoryKeyword('lazada', 'Shopping'),
    CategoryKeyword('shopping', 'Shopping'),
    CategoryKeyword('watsons', 'Healthcare'),
    CategoryKeyword('pharmacy', 'Healthcare'),
    CategoryKeyword('clinic', 'Healthcare'),
    CategoryKeyword('netflix', 'Entertainment'),
    CategoryKeyword('cinema', 'Entertainment'),
    CategoryKeyword('spotify', 'Entertainment'),
  ];
}
