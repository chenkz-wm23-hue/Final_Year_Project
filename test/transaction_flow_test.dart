import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/screens/expense_screen.dart';

void main() {
  testWidgets(
    'expense form validates, saves and deletes through confirmation',
    (tester) async {
      final store = ExpenseStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ExpenseScope(store: store, child: child!),
          home: const Scaffold(body: ExpenseScreen()),
        ),
      );
      await tester.tap(find.text('Add Expense'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a description'), findsOneWidget);
      expect(find.text('Enter an amount greater than zero'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'KFC lunch test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '42.50');
      await tester.ensureVisible(find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();
      expect(store.expense, 69.5);
      expect(store.entries.last.category, 'Food');
      final row = find.ancestor(
        of: find.text('KFC lunch test'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(store.expense, 27);
      expect(find.text('KFC lunch test'), findsNothing);
    },
  );
}
