import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/presentation/screens/budget_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';

void main() {
  for (final income in [false, true]) {
    testWidgets(
      '${income ? "Income" : "Expense"} rejects database-incompatible input before saving',
      (tester) async {
        final store = ExpenseStore();
        addTearDown(store.dispose);
        final count = store.entries.length;
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) => ExpenseScope(store: store, child: child!),
            home: TransactionFormScreen(income: income),
          ),
        );
        await tester.enterText(find.byType(TextFormField).first, 'Test entry');
        for (final amount in ['12.345', '10000000000', '1e3']) {
          await tester.enterText(find.byType(TextFormField).at(1), amount);
          await tester.pumpAndSettle();
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.text('Save ${income ? "Income" : "Expense"}'),
          );
          await tester.tap(find.text('Save ${income ? "Income" : "Expense"}'));
          await tester.pumpAndSettle();
          expect(find.textContaining('up to 2 decimal places'), findsOneWidget);
          expect(store.entries.length, count);
        }
        await tester.enterText(find.byType(TextFormField).at(1), '12.34');
        await tester.enterText(find.byType(TextFormField).first, 'x' * 501);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text('Save ${income ? "Income" : "Expense"}'),
        );
        await tester.tap(find.text('Save ${income ? "Income" : "Expense"}'));
        await tester.pumpAndSettle();
        expect(
          find.text('Keep the description within 500 characters'),
          findsOneWidget,
        );
        expect(store.entries.length, count);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'budget validates precision and limit then saves a valid amount',
    (tester) async {
      final store = ExpenseStore();
      addTearDown(store.dispose);
      final initial = store.budget;
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ExpenseScope(store: store, child: child!),
          home: const Scaffold(body: BudgetScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final budgetAction = find.text(initial > 0 ? 'Update Budget' : 'Set Budget');
      await tester.ensureVisible(budgetAction);
      await tester.tap(budgetAction);
      await tester.pumpAndSettle();
      for (final value in ['12.345', '10000000000']) {
        await tester.enterText(find.byType(TextFormField), value);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.textContaining('up to 2 decimal places'), findsOneWidget);
        expect(store.budget, initial);
      }
      await tester.enterText(find.byType(TextFormField), '1234.56');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(store.budget, 1234.56);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
