import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/business_logic/receipt_exchange.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/theme/app_theme.dart';

void main() {
  Future<ExpenseStore> open(
    WidgetTester tester,
    Future<ReceiptRate> Function(String) loader,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = ExpenseStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (_, child) => ExpenseScope(store: store, child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TransactionFormScreen(income: false, rateLoader: loader),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Travel lunch');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.ensureVisible(find.byKey(const ValueKey('expenseCurrency')));
    await tester.tap(find.byKey(const ValueKey('expenseCurrency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text(label)),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'foreign expense converts, accepts corrected RM and saves only RM',
    (tester) async {
      final store = await open(
        tester,
        (_) async => (rate: 4.5, date: '2026-11-13'),
      );
      final count = store.entries.length;
      await tap(tester, 'Convert to RM');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('convertedRmAmount')),
            )
            .controller!
            .text,
        '45.00',
      );
      await tester.enterText(
        find.byKey(const ValueKey('convertedRmAmount')),
        '44.80',
      );
      await tap(tester, 'Save Expense');
      expect(store.entries.length, count + 1);
      expect(store.entries.last.amount, 44.80);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed conversion requires a valid manually reviewed RM amount',
    (tester) async {
      final store = await open(
        tester,
        (_) async => throw const FormatException(),
      );
      final count = store.entries.length;
      await tap(tester, 'Convert to RM');
      expect(find.textContaining('Conversion unavailable'), findsOneWidget);
      await tap(tester, 'Save Expense');
      expect(store.entries.length, count);
      await tester.enterText(
        find.byKey(const ValueKey('convertedRmAmount')),
        '42.00',
      );
      await tap(tester, 'Save Expense');
      expect(store.entries.last.amount, 42);
    },
  );
  testWidgets(
    'editing source amount ignores an outdated in-flight conversion',
    (tester) async {
      final pending = Completer<ReceiptRate>();
      await open(tester, (_) => pending.future);
      await tap(tester, 'Convert to RM');
      await tester.enterText(find.byType(TextFormField).at(1), '20');
      pending.complete((rate: 4.5, date: '2026-11-13'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('convertedRmAmount')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
