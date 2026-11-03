import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/main.dart' as app;
import 'package:final_year_project/presentation/app_shell.dart';
import 'package:final_year_project/presentation/screens/budget_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/data/repositories/supabase_expense_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Live income, expense and budget saves persist without crashes', (
    tester,
  ) async {
    Future<void> tap(String label) async {
      await tester.ensureVisible(find.text(label).last);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    Future<void> waitGone(Finder finder) async {
      for (var i = 0; i < 120 && finder.evaluate().isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(finder, findsNothing);
      expect(tester.takeException(), isNull);
    }

    await app.main();
    for (var i = 0; i < 120 && find.byType(AppShell).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(
      find.byType(AppShell),
      findsOneWidget,
      reason:
          'Signed in: ${Supabase.instance.client.auth.currentUser != null}; '
          'login entry visible: ${find.text("Get started").evaluate().isNotEmpty}; '
          'load error: ${find.textContaining("could not be loaded").evaluate().isNotEmpty}',
    );
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser!.id;
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final original = await client
        .from('budgets')
        .select()
        .eq('user_id', uid)
        .eq('month', month)
        .maybeSingle();
    final marker = 'Regression ${DateTime.now().microsecondsSinceEpoch}';
    try {
      for (final income in [true, false]) {
        final type = income ? 'Income' : 'Expense';
        if (income) {
          await tester.tap(find.byTooltip('Open navigation menu'));
          await tester.pumpAndSettle();
          await tap('Income');
        } else {
          await tap('Expense');
        }
        await tap('Add $type');
        await tap('Save $type');
        expect(find.text('Enter a description'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).at(0),
          '$marker $type',
        );
        await tester.enterText(find.byType(TextFormField).at(1), '0');
        await tap('Save $type');
        expect(find.text('Enter an amount greater than zero'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField).at(1),
          income ? '123.45' : '12.34',
        );
        await tap('Save $type');
        await waitGone(find.byType(TransactionFormScreen));
        final rows = await client
            .from('transactions')
            .select()
            .eq('user_id', uid)
            .eq('description', '$marker $type');
        expect(rows, hasLength(1));
        expect(rows.single['amount'], income ? 123.45 : 12.34);
        expect(rows.single['transaction_type'], type.toLowerCase());
        expect(find.text('$marker $type'), findsOneWidget);
      }
      await tap('Budget');
      await tap('Update Budget');
      await tester.enterText(find.byType(TextFormField), '0');
      await tap('Save');
      expect(find.text('Enter a positive budget'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '987.65');
      await tap('Save');
      await waitGone(find.byType(AlertDialog));
      expect(find.text('RM 987.65'), findsOneWidget);
      final fresh = SupabaseExpenseRepository(client, uid);
      await fresh.load();
      expect(fresh.budgetFor(now)!.amount, 987.65);
      expect(
        fresh.transactions.where((e) => e.description.startsWith(marker)),
        hasLength(2),
      );
      await tap('Update Budget');
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
        '987.65',
      );
      await tap('Cancel');
      await waitGone(find.byType(AlertDialog));
      // Force a deterministic budget alert using only a temporary budget.
      await tap('Update Budget');
      await tester.enterText(find.byType(TextFormField), '0.01');
      await tap('Save');
      await waitGone(find.byType(AlertDialog));
      final store = ExpenseScope.of(tester.element(find.byType(BudgetScreen)));
      expect(store.insightsUnavailable, isFalse);
      final recommendations = await client
          .from('recommendations')
          .select()
          .eq('user_id', uid)
          .eq('month', month);
      final alerts = await client
          .from('risk_alerts')
          .select()
          .eq('user_id', uid)
          .eq('month', month);
      expect(recommendations.any((r) => r['rule_code'] == 'budget'), isTrue);
      expect(
        alerts.any(
          (r) => r['rule_code'] == 'budget' && r['severity'] == 'high',
        ),
        isTrue,
      );
      expect(
        store.recommendations.map((r) => r.title),
        unorderedEquals(recommendations.map((r) => r['title'])),
      );
      expect(
        store.riskAlerts.map((r) => r.title),
        unorderedEquals(alerts.map((r) => r['title'])),
      );
      await fresh.load();
      expect(fresh.recommendationsFor(now).length, recommendations.length);
      expect(fresh.riskAlertsFor(now).length, alerts.length);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tap('Recommendations');
      expect(find.text('Revisit your monthly plan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tap('Risk Alerts');
      expect(find.text('Monthly budget exceeded'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      for (final type in ['Income', 'Expense']) {
        await client
            .from('transactions')
            .delete()
            .eq('user_id', uid)
            .eq('description', '$marker $type');
        expect(
          await client
              .from('transactions')
              .select('id')
              .eq('user_id', uid)
              .eq('description', '$marker $type'),
          isEmpty,
        );
      }
      if (original == null) {
        await client
            .from('budgets')
            .delete()
            .eq('user_id', uid)
            .eq('month', month);
      } else {
        await client
            .from('budgets')
            .update({'amount': original['amount']})
            .eq('user_id', uid)
            .eq('id', original['id']);
      }
      final restored = await client
          .from('budgets')
          .select()
          .eq('user_id', uid)
          .eq('month', month)
          .maybeSingle();
      expect(restored?['amount'], original?['amount']);
    }
  });
}
