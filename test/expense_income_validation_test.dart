import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/business_logic/expense_validation.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';

void main() {
  Future<ExpenseStore> emptyStore() async {
    final store = ExpenseStore();
    for (final entry in store.entries.toList()) {
      await store.delete(entry.id);
    }
    addTearDown(store.dispose);
    return store;
  }

  test(
    'expenses require income in their month, including income-to-expense edits',
    () async {
      final store = await emptyStore();
      final month = store.month;
      Future<void> expense({int? id, DateTime? date}) => store.save(
        id: id,
        description: 'Lunch',
        amount: 25,
        date: date ?? month,
        category: 'Food',
        income: false,
      );
      await expectLater(expense(), throwsA(isA<ExpenseValidationException>()));
      await store.save(
        description: 'Salary',
        amount: 10,
        date: DateTime(month.year, month.month - 1),
        category: 'Salary',
        income: true,
      );
      await expectLater(expense(), throwsA(isA<ExpenseValidationException>()));
      await store.save(
        description: 'Salary',
        amount: 1000,
        date: month,
        category: 'Salary',
        income: true,
      );
      final salaryId = store.entries.last.id;
      await expectLater(
        expense(id: salaryId),
        throwsA(isA<ExpenseValidationException>()),
      );
      await expense();
      expect(store.expense, 25);
      final id = store.entries.last.id;
      await expectLater(
        expense(id: id, date: DateTime(month.year, month.month + 1)),
        throwsA(isA<ExpenseValidationException>()),
      );
      expect(store.expense, 25);
      await store.delete(salaryId);
      await expectLater(expense(), throwsA(isA<ExpenseValidationException>()));
    },
  );

  testWidgets(
    'manual expense shows guidance and preserves entered values without income',
    (tester) async {
      final store = await emptyStore();
      await tester.binding.setSurfaceSize(const Size(800, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ExpenseScope(store: store, child: child!),
          home: const TransactionFormScreen(income: false),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Lunch');
      await tester.enterText(find.byType(TextFormField).at(1), '25');
      await tester.ensureVisible(find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();
      expect(find.text(ExpenseValidationException.message), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(store.entries, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
