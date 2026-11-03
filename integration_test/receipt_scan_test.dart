import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:final_year_project/business_logic/receipt_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:final_year_project/presentation/screens/receipt_scan_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';

class FixturePicker extends ImagePicker {
  FixturePicker(this.paths);
  final List<String> paths;
  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile(paths.removeAt(0));
}

Future<String> receiptImage(
  Directory dir,
  String total, {
  String currency = 'RM',
  String merchant = 'KFC',
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
  final lines = [merchant, 'Subtotal 10.00', 'FINAL'];
  var y = 35.0;
  for (final line in [
    ...lines,
    'GRAND TOTAL $currency $total',
    'Cash paid 100.00',
  ]) {
    final painter = TextPainter(
      text: TextSpan(
        text: line,
        style: const TextStyle(color: Colors.black, fontSize: 40),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(25, y));
    painter.dispose();
    y += 70;
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(760, 450);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${dir.path}/$total.png');
  await file.writeAsBytes(png!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return file.path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native OCR, edit, rescan, discard and explicit expense save', (
    tester,
  ) async {
    final dir = await Directory.systemTemp.createTemp('receipt_test');
    addTearDown(() => dir.delete(recursive: true));
    final first = await receiptImage(dir, '12.80', currency: 'USD');
    final second = await receiptImage(dir, '23.40', merchant: 'PETROL STATION');
    final picker = FixturePicker([first, second, first]);
    final store = ExpenseStore();
    final original = store.expense;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ExpenseScope(store: store, child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReceiptScanScreen(picker: picker),
                ),
              ),
              child: const Text('Scan'),
            ),
          ),
        ),
      ),
    );
    Future<void> tap(String text) async {
      final target = find.text(text);
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    String value() => tester
        .widget<TextFormField>(find.byType(TextFormField).first)
        .controller!
        .text;
    await tap('Scan');
    await tap('Choose photo');
    final guidance = tester
        .widget<Text>(find.textContaining('1 USD = RM'))
        .data!;
    final rate = double.parse(
      guidance.split('1 USD = RM ').last.split('\n').first,
    );
    expect(value(), (12.80 * rate).toStringAsFixed(2));
    expect(find.text('Receipt summary'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(store.expense, original);
    await tap('Scan again');
    expect(value(), '23.40');
    final scanned = await readReceipt(second);
    expect(
      find.text('Fuel'),
      findsOneWidget,
      reason:
          'OCR: ${scanned.lines}, category: ${store.suggestReceiptCategory(scanned.lines)}',
    );
    expect(store.expense, original);
    await tap('Discard');
    expect(store.expense, original);
    await tap('Scan');
    await tap('Take photo');
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tap('Add expense');
    expect(store.expense, original);
    await tester.enterText(find.byType(TextFormField).first, '14.20');
    await tap('Add expense');
    expect(store.expense, closeTo(original + 14.20, .001));
    expect(store.entries.last.category, 'Food');
    expect(find.byType(ReceiptScanScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
