import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:final_year_project/business_logic/receipt_reader.dart';
import 'package:final_year_project/presentation/screens/receipt_scan_screen.dart';
import 'package:final_year_project/presentation/screens/receipt_viewer_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';

import 'receipt_scan_test.dart' show FixturePicker, receiptImage;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native receipt ML, fallback, rescan and category correction', (
    tester,
  ) async {
    final dir = await Directory.systemTemp.createTemp('receipt_ml');
    addTearDown(() => dir.delete(recursive: true));
    final store = ExpenseStore();
    final initialCount = store.entries.length;
    final ml = await receiptImage(
      dir,
      '24.50',
      merchant: 'KFC fried chicken meal',
    );
    final fallback = await receiptImage(dir, '23.40', merchant: 'KFC');
    final samples = <(String, String, String?, String)>[
      (ml, 'Food', 'machineLearning', 'ml'),
      (fallback, 'Food', 'keyword', 'fallback'),
    ];
    if (const bool.fromEnvironment('RECEIPT_FIXTURES')) {
      for (final sample in <(String, String)>[
        ('maison', 'Shopping'),
        ('tesco', 'Shopping'),
        ('grocery', 'Food'),
        ('invoice', 'Food'),
        ('kfc', 'Food'),
        ('restaurant', 'Food'),
        ('jaya', 'Shopping'),
      ]) {
        final bytes = await rootBundle.load('tmp/ml_receipts/${sample.$1}.png');
        final file = File('${dir.path}/${sample.$1}.png');
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        samples.add((file.path, sample.$2, null, sample.$1));
      }
    }
    final picker = FixturePicker([...samples.map((s) => s.$1), fallback]);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ExpenseScope(store: store, child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReceiptScanScreen(picker: picker),
                ),
              ),
              child: const Text('Scan'),
            ),
          ),
        ),
      ),
    );
    Future<void> tap(String text, {bool waitForIdle = true}) async {
      tester.binding.focusedEditable = null;
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await tester.pumpAndSettle();
      final target = find.text(text);
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(target);
      if (waitForIdle) {
        await tester.pumpAndSettle();
      } else {
        // Saving stays busy while the confirmation dialog awaits a choice.
        await tester.pump(const Duration(seconds: 1));
      }
    }

    await tap('Scan');
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      await tap(i == 0 ? 'Choose photo' : 'Scan again');
      final receipt = await readReceipt(sample.$1);
      final suggestion = store.receiptCategorySuggestion(receipt.lines);
      debugPrint(
        'RECEIPT_RESULT ${sample.$4}: ${suggestion.category}, ${suggestion.source.name}, total=${receipt.total}',
      );
      expect(
        find.text(sample.$2),
        findsOneWidget,
        reason: '${sample.$4}: ${receipt.lines}',
      );
      if (sample.$3 != null) {
        expect(suggestion.source.name, sample.$3);
        expect(find.textContaining('Suggested category'), findsOneWidget);
      }
      expect(store.entries.length, initialCount);
      expect(tester.takeException(), isNull);
    }
    final dropdown = find.byType(DropdownButtonFormField<String>).first;
    await Scrollable.ensureVisible(tester.element(dropdown), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Others').last);
    await tester.pumpAndSettle();
    expect(find.text('Your selected category will be saved.'), findsOneWidget);
    // Amount editing must not overwrite the manual category.
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tap('Add expense');
    expect(store.entries.length, initialCount);
    await Scrollable.ensureVisible(
      tester.element(find.byType(TextFormField).first),
      alignment: .3,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '14.20');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '14.20',
    );
    await tap('Add expense');
    expect(store.entries.length, initialCount + 1);
    expect(store.entries.last.category, 'Others');
    expect(store.entries.last.amount, 14.20);
    expect(find.byType(ReceiptScanScreen), findsNothing);
    expect(tester.takeException(), isNull);
    debugPrint('RECEIPT_SAVE_PASS manual Others RM14.20 saved once');
    expect(store.entries.last.receiptPath, isNotNull);
    await tap('Scan');
    await tap('Choose photo');
    await Scrollable.ensureVisible(
      tester.element(find.byType(TextFormField).first),
      alignment: .3,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '14.20');
    await tester.pumpAndSettle();
    await tap('Add expense', waitForIdle: false);
    expect(find.text('Possible duplicate receipt'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(store.entries.length, initialCount + 1);
    await tap('Add expense', waitForIdle: false);
    await tester.tap(find.text('Add anyway'));
    await tester.pumpAndSettle();
    expect(store.entries.length, initialCount + 2);
    final navigator = Navigator.of(tester.element(find.text('Scan')));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptViewerScreen(entry: store.entries.last),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugPrint(
      'RECEIPT_DUPLICATE_UI_PASS cancel and add anyway; attachment reopened',
    );

    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
