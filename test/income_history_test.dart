import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/screens/income_history_screen.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/widgets/live_transaction_tile.dart';

void main() {
  testWidgets(
    'income history spans months, excludes expenses, searches and opens editing',
    (tester) async {
      final store = ExpenseStore();
      addTearDown(store.dispose);
      for (final entry in store.entries.toList()) {
        await store.delete(entry.id);
      }
      await store.save(
        description: 'January salary',
        amount: 2000,
        date: DateTime(2026, 1, 2),
        category: 'Salary',
        income: true,
      );
      await store.save(
        description: 'September freelance',
        amount: 500,
        date: DateTime(2026, 9, 2),
        category: 'Freelance',
        income: true,
      );
      await store.save(
        description: 'Lunch expense',
        amount: 20,
        date: DateTime(2026, 9, 3),
        category: 'Food',
        income: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ExpenseScope(store: store, child: child!),
          home: const IncomeHistoryScreen(),
        ),
      );
      expect(find.text('Lunch expense'), findsNothing);
      expect(
        tester
            .widgetList<LiveTransactionTile>(find.byType(LiveTransactionTile))
            .map((w) => w.entry.description),
        ['September freelance', 'January salary'],
      );
      await tester.enterText(find.byType(TextField), 'January');
      await tester.pumpAndSettle();
      expect(find.text('September freelance'), findsNothing);
      await tester.tap(find.text('January salary'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text('Edit Income'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
