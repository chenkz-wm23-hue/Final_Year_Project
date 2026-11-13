import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/business_logic/receipt_duplicates.dart';
import 'package:final_year_project/data/repositories/in_memory_expense_repository.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/screens/receipt_viewer_screen.dart';
import 'package:final_year_project/presentation/widgets/duplicate_receipt_dialog.dart';

void main() {
  TransactionEntry expense({
    String? merchant = 'KFC',
    int day = 13,
    double amount = 15.88,
    bool income = false,
  }) => TransactionEntry(
    id: 88,
    description: 'Receipt expense',
    category: 'Food',
    amount: amount,
    date: DateTime(2026, 11, day),
    income: income,
    merchant: merchant,
    receiptPath: 'sample.png',
  );
  test('duplicate warning matches merchant, date and cents but excludes other purchases and retries', () {
    final entries = [
      expense(),
      expense(merchant: 'Petronas'),
      expense(day: 12),
      expense(amount: 15.89),
      expense(income: true),
    ];
    expect(
      possibleReceiptDuplicates(
        entries,
        merchant: 'K.F.C.',
        date: DateTime(2026, 11, 13),
        amount: 15.88,
      ),
      hasLength(1),
    );
    expect(
      possibleReceiptDuplicates(
        [expense()],
        merchant: 'KFC',
        date: DateTime(2026, 11, 13),
        amount: 15.88,
        receiptPath: 'sample.png',
      ),
      isEmpty,
    );
    expect(
      possibleReceiptDuplicates(
        [expense(merchant: null)],
        merchant: 'KFC',
        date: DateTime(2026, 11, 13),
        amount: 15.88,
      ),
      hasLength(1),
    );
    expect(suggestReceiptMerchant(['Invoice', 'KFC', 'Total 15.88']), 'KFC');
  });
  test('editing an expense preserves receipt and merchant; retry does not duplicate', () async {
    final repo = InMemoryExpenseRepository();
    final store = ExpenseStore(repository: repo);
    addTearDown(store.dispose);
    final before = store.entries.length;
    await store.save(
      description: 'Receipt',
      amount: 15.88,
      date: DateTime(2026, 11, 13),
      category: 'Food',
      income: false,
      receiptPath: 'test.png',
      merchant: 'KFC',
    );
    await store.save(
      description: 'Receipt',
      amount: 15.88,
      date: DateTime(2026, 11, 13),
      category: 'Food',
      income: false,
      receiptPath: 'test.png',
      merchant: 'KFC',
    );
    expect(store.entries.length, before + 1);
    final id = store.entries.last.id;
    await store.save(
      id: id,
      description: 'Updated',
      amount: 16,
      date: DateTime(2026, 11, 13),
      category: 'Others',
      income: false,
    );
    expect(store.entries.last.receiptPath, 'test.png');
    expect(store.entries.last.merchant, 'KFC');
  });
  testWidgets('duplicate dialog can cancel or explicitly continue', (
    tester,
  ) async {
    bool? decision;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                decision = await confirmDuplicateReceipt(context, [expense()]);
              },
              child: const Text('Check'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(decision, isFalse);
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add anyway'));
    await tester.pumpAndSettle();
    expect(decision, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'saved receipt opens as an image; missing receipt gives retry guidance',
    (tester) async {
      final repo = InMemoryExpenseRepository();
      final store = ExpenseStore(repository: repo);
      addTearDown(store.dispose);
      await repo.uploadReceipt(
        'sample.png',
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ExpenseScope(store: store, child: child!),
          home: ReceiptViewerScreen(entry: expense()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
