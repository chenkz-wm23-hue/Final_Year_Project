import 'package:supabase_flutter/supabase_flutter.dart';

import 'expense_repository.dart';
import 'insight_repository.dart';
import '../models/recommendation.dart';
import '../models/risk_alert.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/keyword.dart';

/// One repository per authenticated account. Cache changes only after server success.
class SupabaseExpenseRepository
    implements ExpenseRepository, InsightRepository {
  SupabaseExpenseRepository(this.client, this.userId);
  final SupabaseClient client;
  final String userId;
  List<TransactionEntry> _entries = [];
  List<MonthlyBudget> _budgets = [];
  List<Map<String, dynamic>> _categoryRows = [];
  List<CategoryKeyword> _keywords = [];
  List<Map<String, dynamic>> _recommendations = [], _alerts = [];
  @override
  bool insightsUnavailable = false;

  @override
  List<Recommendation> recommendationsFor(DateTime month) => _recommendations
      .where((r) => r['month'] == _date(DateTime(month.year, month.month)))
      .map(
        (r) => Recommendation(
          title: r['title'] as String,
          description: r['description'] as String,
          label: r['label'] as String,
        ),
      )
      .toList();

  @override
  List<RiskAlert> riskAlertsFor(DateTime month) => _alerts
      .where((r) => r['month'] == _date(DateTime(month.year, month.month)))
      .map(
        (r) => RiskAlert(
          title: r['title'] as String,
          description: r['description'] as String,
          label: r['label'] as String,
          severity: r['severity'] == 'high'
              ? RiskSeverity.high
              : RiskSeverity.warning,
        ),
      )
      .toList();

  @override
  Future<void> refreshInsights() async {
    try {
      _checkSession();
      final recommendations = await _readAll('recommendations', owned: true);
      final alerts = await _readAll('risk_alerts', owned: true);
      _checkSession();
      _recommendations = recommendations;
      _alerts = alerts;
      insightsUnavailable = false;
    } catch (_) {
      // Source writes may already be committed. Do not report a failed save
      // and encourage a duplicate transaction just because this read failed.
      _recommendations = [];
      _alerts = [];
      insightsUnavailable = true;
    }
  }

  UserProfile _user = const UserProfile(name: '', email: '');
  void _checkSession() {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Your session changed. Please sign in again.');
    }
  }

  Future<List<Map<String, dynamic>>> _readAll(
    String table, {
    bool owned = false,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (int offset = 0; ; offset += 500) {
      var query = client.from(table).select();
      if (owned) query = query.eq('user_id', userId);
      final page = await query.order('id').range(offset, offset + 499);
      rows.addAll(page);
      if (page.length < 500) return rows;
    }
  }

  Future<void> load() async {
    _checkSession();
    final categories = await _readAll('categories');
    final keywords = await _readAll('keywords');
    final profile = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    final transactions = await _readAll('transactions', owned: true);
    final budgets = await _readAll('budgets', owned: true);
    _checkSession();
    _categoryRows = categories;
    _keywords = keywords
        .map(
          (r) => CategoryKeyword(
            r['keyword'] as String,
            categories.firstWhere((c) => c['id'] == r['category_id'])['name']
                as String,
          ),
        )
        .toList();
    _user = UserProfile(
      name: profile['full_name'] as String,
      email: client.auth.currentUser!.email ?? '',
      phone: profile['phone'] as String,
      address: profile['address'] as String,
    );
    _entries = transactions.map(_transaction).toList();
    _budgets = budgets.map((r) {
      final month = DateTime.parse(r['month'] as String);
      return MonthlyBudget(
        year: month.year,
        month: month.month,
        amount: (r['amount'] as num).toDouble(),
      );
    }).toList();
    await refreshInsights();
  }

  TransactionEntry _transaction(Map<String, dynamic> row) => TransactionEntry(
    id: (row['id'] as num).toInt(),
    description: row['description'] as String,
    category:
        _categoryRows.firstWhere((c) => c['id'] == row['category_id'])['name']
            as String,
    amount: (row['amount'] as num).toDouble(),
    date: DateTime.parse(row['transaction_date'] as String),
    income: row['transaction_type'] == 'income',
  );
  @override
  List<TransactionEntry> get transactions => List.unmodifiable(_entries);
  // Zero is a new-entry marker. Supabase generates the actual ID on INSERT.
  @override
  int nextTransactionId() => 0;
  @override
  Future<void> upsertTransaction(TransactionEntry entry) async {
    _checkSession();
    final type = entry.income ? 'income' : 'expense';
    final category = _categoryRows.firstWhere(
      (c) => c['name'] == entry.category && c['transaction_type'] == type,
    );
    final values = {
      'user_id': userId,
      'description': entry.description,
      'amount': entry.amount,
      'transaction_date': _date(entry.date),
      'transaction_type': type,
      'category_id': category['id'],
    };
    final Map<String, dynamic> row;
    if (entry.id == 0) {
      row = await client.from('transactions').insert(values).select().single();
    } else {
      row = await client
          .from('transactions')
          .update(values)
          .eq('id', entry.id)
          .eq('user_id', userId)
          .select()
          .single();
    }
    _checkSession();
    final saved = _transaction(row);
    _entries = [..._entries.where((e) => e.id != saved.id), saved];
    await refreshInsights();
  }

  @override
  Future<void> deleteTransaction(int id) async {
    _checkSession();
    await client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();
    _checkSession();
    _entries = _entries.where((e) => e.id != id).toList();
    await refreshInsights();
  }

  @override
  MonthlyBudget? budgetFor(DateTime month) {
    for (final budget in _budgets) {
      if (budget.year == month.year && budget.month == month.month) {
        return budget;
      }
    }
    return null;
  }

  @override
  Future<void> saveBudget(MonthlyBudget budget) async {
    _checkSession();
    final row = await client
        .from('budgets')
        .upsert({
          'user_id': userId,
          'month': _date(DateTime(budget.year, budget.month)),
          'amount': budget.amount,
        }, onConflict: 'user_id,month')
        .select()
        .single();
    _checkSession();
    final saved = MonthlyBudget(
      year: budget.year,
      month: budget.month,
      amount: (row['amount'] as num).toDouble(),
    );
    _budgets = [..._budgets.where((b) => b.key != saved.key), saved];
    await refreshInsights();
  }

  @override
  UserProfile get user => _user;
  @override
  Future<void> saveUser(UserProfile profile) async {
    _checkSession();
    // Email is owned by Auth, not the profiles table. The profile form is read-only for email.
    await client
        .from('profiles')
        .update({
          'full_name': profile.name,
          'phone': profile.phone,
          'address': profile.address,
        })
        .eq('id', userId)
        .select()
        .single();
    _checkSession();
    _user = UserProfile(
      name: profile.name,
      email: client.auth.currentUser!.email ?? '',
      phone: profile.phone,
      address: profile.address,
    );
  }

  @override
  List<Category> get categories => _categoryRows
      .map(
        (r) => Category(
          r['name'] as String,
          income: r['transaction_type'] == 'income',
        ),
      )
      .toList();
  @override
  List<CategoryKeyword> get keywords => List.unmodifiable(_keywords);
  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
