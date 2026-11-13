import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/screens/dashboard_screen.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/presentation/screens/receipt_scan_screen.dart';
import 'package:final_year_project/presentation/widgets/budget_status_notice.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';

void main() {
  testWidgets('quick actions open expense and receipt screens safely', (
    tester,
  ) async {
    final store = ExpenseStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ExpenseScope(store: store, child: child!),
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
    await tester.ensureVisible(find.text('Add Expense'));
    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TransactionFormScreen>(find.byType(TransactionFormScreen))
          .income,
      isFalse,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Scan Receipt'));
    await tester.tap(find.text('Scan Receipt'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptScanScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  testWidgets(
    'budget warnings distinguish approaching, full and exceeded limits',
    (tester) async {
      for (final sample in [
        (1200.0, '80%'),
        (1500.0, 'full budget'),
        (1600.0, 'RM 100.00 over budget'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BudgetStatusNotice(spent: sample.$1, budget: 1500),
            ),
          ),
        );
        expect(find.textContaining(sample.$2), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
