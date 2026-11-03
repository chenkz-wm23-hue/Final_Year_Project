import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/screens/dashboard_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/widgets/finance_charts.dart';

void main() {
  testWidgets(
    'expense stays within budget and dashboard adds and edits income',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = ExpenseStore();
      for (final entry in store.entries.toList()) {
        await store.delete(entry.id);
      }
      await store.setBudget(1500);
      await store.save(
        description: 'Toys',
        amount: 300,
        date: DateTime.now(),
        category: 'Entertainment',
        income: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ExpenseScope(store: store, child: child!),
          home: const Scaffold(body: DashboardScreen()),
        ),
      );
      expect(store.balance, -300);
      expect(store.remaining, 1200);
      expect(find.text('RM 1200.00 budget remaining'), findsOneWidget);
      expect(find.text('Your spending is within budget.'), findsOneWidget);
      expect(
        find.textContaining('No received income recorded'),
        findsOneWidget,
      );
      await tester.tap(find.text('Add Income'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test salary');
      await tester.enterText(find.byType(TextFormField).at(1), '2000');
      await tester.tap(find.text('Save Income'));
      await tester.pumpAndSettle();
      expect(store.balance, 1700);
      expect(store.remaining, 1200);
      expect(
        tester.widget<CashFlowChart>(find.byType(CashFlowChart)).income,
        2000,
      );
      await tester.tap(find.text('Manage Income'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test salary'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Income'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), '2500');
      await tester.tap(find.text('Save Income'));
      await tester.pumpAndSettle();
      expect(store.income, 2500);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<CashFlowChart>(find.byType(CashFlowChart)).income,
        2500,
      );
      store.changeMonth(1);
      await tester.pumpAndSettle();
      expect(
        tester.widget<CashFlowChart>(find.byType(CashFlowChart)).income,
        0,
      );
      expect(
        tester.widget<CashFlowChart>(find.byType(CashFlowChart)).expense,
        0,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets('budget chart handles empty, full and overspent budgets', (
    tester,
  ) async {
    for (final spent in [0.0, 1500.0, 1800.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BudgetChart(spent: spent, budget: 1500)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('${(spent / 1500 * 100).round()}%'), findsOneWidget);
      expect(
        find.text('Over budget · RM 300.00'),
        spent > 1500 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
