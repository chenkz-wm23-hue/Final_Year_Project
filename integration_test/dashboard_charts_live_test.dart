import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/main.dart' as app;
import 'package:final_year_project/presentation/app_shell.dart';
import 'package:final_year_project/presentation/screens/dashboard_screen.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/widgets/finance_charts.dart';
import 'package:final_year_project/data/repositories/supabase_expense_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Dashboard income buttons and charts follow live income and expense edits',
    (tester) async {
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label).last);
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      Future<void> top() async {
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
      }

      Future<void> save(
        String type,
        String amount, {
        String? description,
      }) async {
        if (description != null) {
          await tester.enterText(find.byType(TextFormField).first, description);
        }
        await tester.enterText(find.byType(TextFormField).at(1), amount);
        await tap('Save $type');
        for (
          var i = 0;
          i < 120 && find.byType(TransactionFormScreen).evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpAndSettle();
        expect(find.byType(TransactionFormScreen), findsNothing);
        expect(tester.takeException(), isNull);
      }

      await app.main();
      for (
        var i = 0;
        i < 120 && find.byType(AppShell).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(
        find.byType(AppShell),
        findsOneWidget,
        reason: 'Sign in on the emulator before this live test.',
      );
      final store = ExpenseScope.of(
        tester.element(find.byType(DashboardScreen)),
      );
      final baseIncome = store.income,
          baseExpense = store.expense,
          budget = store.budget;
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser!.id;
      final marker = 'Chart test ${DateTime.now().microsecondsSinceEpoch}';
      Future<void> charts(double incomeDelta, double expenseDelta) async {
        await top();
        await tester.scrollUntilVisible(
          find.byType(CashFlowChart),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final chart = tester.widget<CashFlowChart>(find.byType(CashFlowChart));
        expect(chart.income, closeTo(baseIncome + incomeDelta, .001));
        expect(chart.expense, closeTo(baseExpense + expenseDelta, .001));
        expect(
          find.text('Received income · ${money(baseIncome + incomeDelta)}'),
          findsOneWidget,
        );
        expect(
          find.text('Recorded expenses · ${money(baseExpense + expenseDelta)}'),
          findsOneWidget,
        );
        await tap('Budget');
        await tester.scrollUntilVisible(
          find.byType(BudgetChart),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final ring = tester.widget<BudgetChart>(find.byType(BudgetChart));
        expect(ring.spent, closeTo(baseExpense + expenseDelta, .001));
        expect(ring.budget, budget);
        expect(
          find.text(
            '${((baseExpense + expenseDelta) / budget * 100).toStringAsFixed(0)}%',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tap('Home');
        await top();
      }

      try {
        await top();
        await tap('Add Income');
        await save('Income', '123.45', description: '$marker income');
        await charts(123.45, 0);
        await tap('Manage Income');
        await tester.enterText(find.byType(TextField).first, '$marker income');
        await tester.pumpAndSettle();
        await tap('$marker income');
        expect(find.text('Edit Income'), findsOneWidget);
        await save('Income', '234.56');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await charts(234.56, 0);
        await tester.tap(find.byTooltip('Add expense'));
        await tester.pumpAndSettle();
        await save('Expense', '12.34', description: '$marker expense');
        await charts(234.56, 12.34);
        await tap('Expense');
        await tester.enterText(find.byType(TextField).first, '$marker expense');
        await tester.pumpAndSettle();
        await tap('$marker expense');
        await save('Expense', '23.45');
        await tap('Home');
        await charts(234.56, 23.45);
        final fresh = SupabaseExpenseRepository(client, uid);
        await fresh.load();
        expect(
          fresh.transactions
              .singleWhere((e) => e.description == '$marker income')
              .amount,
          234.56,
        );
        expect(
          fresh.transactions
              .singleWhere((e) => e.description == '$marker expense')
              .amount,
          23.45,
        );
      } finally {
        final rows = await client
            .from('transactions')
            .select('id,description')
            .eq('user_id', uid)
            .inFilter('description', ['$marker income', '$marker expense']);
        for (final row in rows) {
          await store.delete((row['id'] as num).toInt());
        }
        expect(
          await client
              .from('transactions')
              .select('id')
              .eq('user_id', uid)
              .inFilter('description', ['$marker income', '$marker expense']),
          isEmpty,
        );
      }
      await charts(0, 0);
    },
  );
}
