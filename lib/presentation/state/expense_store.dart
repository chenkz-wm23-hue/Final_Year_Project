import 'package:flutter/material.dart';

import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/in_memory_expense_repository.dart';
import '../../data/models/transaction.dart';
import '../../data/models/recommendation.dart';
import '../../data/models/risk_alert.dart';
import '../../business_logic/transaction_management.dart';
import '../../business_logic/budget_management.dart';
import '../../business_logic/dashboard_calculation.dart';
import '../../business_logic/expense_categorisation.dart';
import '../../business_logic/profile_management.dart';
import '../../business_logic/rule_based_recommendation.dart';
import '../../business_logic/rule_based_risk_evaluator.dart';
export '../../data/models/transaction.dart';
export '../../data/models/category.dart';
export '../../data/models/risk_alert.dart';

String money(double value) => 'RM ${value.toStringAsFixed(2)}';
String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';

/// Presentation state: delegates operations to business services.
class ExpenseStore extends ChangeNotifier {
  ExpenseStore({ExpenseRepository? repository})
    : repository = repository ?? InMemoryExpenseRepository();
  final ExpenseRepository repository;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  late final transactions = TransactionManagement(repository);
  late final budgets = BudgetManagement(repository);
  late final profiles = ProfileManagement(repository);
  final calculator = const DashboardCalculation();
  final recommendationService = const RuleBasedRecommendation();
  final riskService = const RuleBasedRiskEvaluator();
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  List<TransactionEntry> get entries => repository.transactions;
  List<TransactionEntry> get monthly => transactions.forMonth(month);
  DashboardSummary get summary => calculator.calculate(monthly, budget);
  List<Recommendation> get recommendations =>
      recommendationService.generate(summary);
  List<RiskAlert> get riskAlerts => riskService.evaluate(summary);
  String get name => repository.user.name;
  String get email => repository.user.email;
  String get phone => repository.user.phone;
  String get address => repository.user.address;
  String get monthLabel =>
      '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month.month - 1]} ${month.year}';
  double get income => summary.income;
  double get expense => summary.expense;
  double get balance => summary.balance;
  double get budget => budgets.amountFor(month);
  double get remaining => summary.remaining;
  double get ratio => summary.ratio;
  Map<String, double> get categoryTotals => summary.categoryTotals;
  void changeMonth(int offset) {
    month = DateTime(month.year, month.month + offset);
    notifyListeners();
  }

  Future<void> setBudget(double value) async {
    await budgets.save(month, value);
    notifyListeners();
  }

  Future<void> save({
    int? id,
    required String description,
    required double amount,
    required DateTime date,
    required String category,
    required bool income,
  }) async {
    await transactions.save(
      id: id,
      description: description,
      amount: amount,
      date: date,
      category: category,
      income: income,
    );
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await transactions.delete(id);
    notifyListeners();
  }

  Future<void> updateProfile(
    String name,
    String email,
    String phone,
    String address,
  ) async {
    await profiles.update(name, email, phone, address);
    notifyListeners();
  }

  String suggestCategory(String text) =>
      ExpenseCategorisation(repository.keywords).suggest(text);
}

class ExpenseScope extends InheritedNotifier<ExpenseStore> {
  const ExpenseScope({
    super.key,
    required ExpenseStore store,
    required super.child,
  }) : super(notifier: store);
  static ExpenseStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpenseScope>()!.notifier!;
}
