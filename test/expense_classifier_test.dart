import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/business_logic/expense_classifier.dart';
import 'package:final_year_project/business_logic/expense_categorisation.dart';
import 'package:final_year_project/business_logic/category_suggestion.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';

void main() {
  const hybrid = HybridExpenseCategorisation(ExpenseCategorisation([]));

  test('Dart probabilities match trained Python model on all export cases', () {
    final cases =
        jsonDecode(File('ml/parity_cases.json').readAsStringSync()) as List;
    for (final sample in cases) {
      final prediction = ExpenseClassifier.bundled.predict(
        sample['text'] as String,
      )!;
      final expected = sample['probabilities'] as List;
      for (var i = 0; i < expected.length; i++) {
        expect(
          prediction.probabilities[i],
          closeTo(expected[i] as double, 1e-9),
        );
      }
    }
  });

  test('uses trained model for confident descriptions and receipt text', () {
    for (final text in [
      'prescription antibiotics tablets',
      'refill car with ron95 petrol',
    ]) {
      expect(
        hybrid.suggest(text).source,
        CategorySuggestionSource.machineLearning,
      );
    }
    expect(
      hybrid.suggest('prescription antibiotics tablets').category,
      'Healthcare',
    );
    final receipt = hybrid.suggestReceipt([
      'KFC fried chicken meal',
      'Total RM 15.88',
    ]);
    expect(receipt.source, CategorySuggestionSource.machineLearning);
    expect(receipt.category, 'Food');
  });

  test('abstains on unknown sparse and ambiguous text then uses keywords', () {
    expect(ExpenseClassifier.bundled.predict('zzqq xxvv'), isNull);
    expect(ExpenseClassifier.bundled.predict('kfc')!.accepted, isFalse);
    expect(hybrid.suggest('KFC').source, CategorySuggestionSource.keyword);
    expect(hybrid.suggest('zzqq xxvv').category, 'Others');
    expect(
      hybrid.suggest('Total RM 20.00').source,
      CategorySuggestionSource.unknown,
    );
    expect(
      hybrid.suggestReceipt(['JAYA GROCER', 'chicken milk bread']).category,
      'Shopping',
    );
    const disabled = HybridExpenseCategorisation(
      ExpenseCategorisation([]),
      enableModel: false,
    );
    expect(
      disabled.suggest('KFC chicken meal').source,
      CategorySuggestionSource.keyword,
    );
  });

  testWidgets('manual category survives description edits and is saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = ExpenseStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ExpenseScope(store: store, child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const TransactionFormScreen(income: false),
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
    await tester.enterText(
      find.byType(TextFormField).first,
      'prescription antibiotics tablets',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Suggested category'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Others').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'kfc fried chicken meal',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '12.50');
    await tester.pumpAndSettle();
    expect(find.text('Your selected category will be saved.'), findsOneWidget);
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();
    final saved = store.entries.singleWhere(
      (e) => e.description == 'kfc fried chicken meal',
    );
    expect(saved.category, 'Others');
    expect(saved.amount, 12.50);
    expect(saved.income, isFalse);
  });
}
