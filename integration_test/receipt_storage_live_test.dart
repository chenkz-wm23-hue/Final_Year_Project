import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:final_year_project/main.dart' as app;
import 'package:final_year_project/presentation/app_shell.dart';
import 'package:final_year_project/presentation/screens/dashboard_screen.dart';
import 'package:final_year_project/presentation/screens/receipt_viewer_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/data/repositories/supabase_expense_repository.dart';
import 'package:final_year_project/business_logic/receipt_duplicates.dart';

import 'receipt_scan_test.dart' show receiptImage;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('private receipt upload reload view edit retry and cleanup', (
    tester,
  ) async {
    await app.main();
    for (var i = 0; i < 120 && find.byType(AppShell).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(
      find.byType(AppShell),
      findsOneWidget,
      reason: 'Requires signed-in tester session',
    );
    final store = ExpenseScope.of(tester.element(find.byType(DashboardScreen)));
    expect(store.name.toLowerCase(), 'tester');
    final repo = store.repository as SupabaseExpenseRepository;
    final directory = await Directory.systemTemp.createTemp(
      'receipt_attachment',
    );
    final key =
        'receipt_attachment_check_${DateTime.now().microsecondsSinceEpoch}';
    String? path;
    try {
      final file = await receiptImage(directory, '17.23', merchant: 'KFC');
      final bytes = await File(file).readAsBytes();
      path = await repo.uploadReceipt(key, bytes);
      for (var attempt = 0; attempt < 2; attempt++) {
        await store.save(
          description: '[TEST] Receipt attachment verification',
          amount: 17.23,
          date: DateTime.now(),
          category: 'Food',
          income: false,
          receiptPath: path,
          merchant: 'KFC',
        );
      }
      await repo.load();
      final saved = repo.transactions
          .where((e) => e.receiptPath == path)
          .toList();
      expect(saved, hasLength(1));
      expect(await repo.downloadReceipt(path), orderedEquals(bytes));
      final candidates = await repo.receiptCandidates(saved.single.date, 17.23);
      expect(
        possibleReceiptDuplicates(
          candidates,
          merchant: 'K.F.C.',
          date: saved.single.date,
          amount: 17.23,
        ),
        isNotEmpty,
      );
      final navigator = Navigator.of(
        tester.element(find.byType(DashboardScreen)),
      );
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptViewerScreen(entry: saved.single),
        ),
      );
      for (
        var i = 0;
        i < 80 && find.byType(InteractiveViewer).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
      navigator.pop();
      await tester.pumpAndSettle();
      await store.save(
        id: saved.single.id,
        description: '[TEST] Edited receipt attachment verification',
        amount: 18,
        date: saved.single.date,
        category: 'Food',
        income: false,
      );
      await repo.load();
      expect(
        repo.transactions
            .singleWhere((e) => e.id == saved.single.id)
            .receiptPath,
        path,
      );
      debugPrint(
        'RECEIPT_STORAGE_LIVE_PASS upload reload view edit duplicate-check and idempotent retry',
      );
    } finally {
      if (path != null) {
        await repo.load();
        for (final entry
            in repo.transactions.where((e) => e.receiptPath == path).toList()) {
          await store.delete(entry.id);
        }
        await repo.client.storage
            .from(SupabaseExpenseRepository.receiptBucket)
            .remove([path]);
        await repo.load();
        expect(repo.transactions.where((e) => e.receiptPath == path), isEmpty);
        debugPrint('RECEIPT_STORAGE_CLEANUP_PASS');
      }
      await directory.delete(recursive: true);
    }
  });
}
