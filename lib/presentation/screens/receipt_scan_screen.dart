import 'dart:math';
import 'dart:ui' as ui;

import '../../business_logic/receipt_duplicates.dart';
import '../../data/repositories/receipt_repository.dart';
import '../widgets/duplicate_receipt_dialog.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../business_logic/account_setup.dart';
import '../../business_logic/receipt_reader.dart';
import '../../business_logic/receipt_exchange.dart';
import '../state/expense_store.dart';
import '../widgets/async_button.dart';
import '../widgets/app_card.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key, this.picker});
  final ImagePicker? picker;
  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  late final picker = widget.picker ?? ImagePicker();
  final amount = TextEditingController();
  final merchant = TextEditingController();
  String? receiptPath;
  String receiptKey = '';
  final description = TextEditingController(text: 'Receipt expense');
  final form = GlobalKey<FormState>();
  Uint8List? photo;
  String? message;
  String? printedTotal;
  String? currency;
  bool rateFailed = false;
  bool busy = false;
  String category = 'Others';
  String categoryGuidance = 'Check or change the category before saving.';
  late DateTime date = DateTime.now();
  bool get supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    if (supported && defaultTargetPlatform == TargetPlatform.android) {
      scan(null);
    }
  }

  Future<void> scan(ImageSource? source) async {
    if (busy) return;
    setState(() {
      busy = true;
    });
    try {
      XFile? file;
      if (source == null) {
        final recovered = await picker.retrieveLostData();
        if (recovered.exception != null) throw recovered.exception!;
        file = recovered.files?.firstOrNull;
      } else {
        file = await picker.pickImage(
          source: source,
          maxWidth: 2400,
          maxHeight: 3200,
          requestFullMetadata: false,
        );
      }
      if (file == null || !mounted) return;
      final rawBytes = await file.readAsBytes();
      if (rawBytes.length > 20971520) {
        throw const FormatException('Image too large');
      }
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: 1600,
        allowUpscaling: false,
      );
      late Uint8List bytes;
      try {
        final frame = await codec.getNextFrame();
        try {
          final png = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (png == null || png.lengthInBytes > 15728640) {
            throw const FormatException('Image too large');
          }
          bytes = png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
      if (!mounted) return;
      setState(() {
        photo = bytes;
        receiptPath = null;
        receiptKey =
            '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
        merchant.clear();
        printedTotal = null;
        currency = null;
        rateFailed = false;
        message = null;
        amount.clear();
        description.text = 'Receipt expense';
        category = 'Others';
        categoryGuidance = 'Check or change the category before saving.';
        date = DateTime.now();
      });
      final receipt = await readReceipt(file.path);
      final total = receipt.total;
      if (!mounted) return;
      final suggested = ExpenseScope.of(context)
          .receiptCategorySuggestion(receipt.lines);
      setState(() {
        printedTotal = total;
        merchant.text = suggestReceiptMerchant(receipt.lines);
        category = expenseCategories.contains(suggested.category)
            ? suggested.category
            : 'Others';
        categoryGuidance = category == 'Others'
            ? 'No clear match. Please choose a category.'
            : 'Suggested category - check or change before saving.';
        message = 'No clear total found. Enter the RM amount or scan again.';
      });
      if (total != null) await convert(receipt.foreignCurrency ?? 'MYR');
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not read the receipt. Check camera or photo access and try a clear, well-lit image.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> convert(String code) async {
    final original = printedTotal!;
    setState(() {
      busy = true;
      rateFailed = false;
      currency = receiptCurrencies.contains(code) ? code : null;
      amount.clear();
      message = null;
    });
    try {
      if (currency == null) {
        setState(
          () => message =
              'Printed total: $code $original. Select the receipt currency to convert it.',
        );
      } else if (code == 'MYR') {
        setState(() {
          amount.text = original;
          message = 'Check the RM amount before adding your expense.';
        });
      } else {
        final quote = await latestReceiptRate(code);
        if (!mounted) return;
        setState(() {
          amount.text = (double.parse(original) * quote.rate).toStringAsFixed(
            2,
          );
          message =
              'Printed total: $code $original\n1 $code = RM ${quote.rate}\nFrankfurter reference rate · ${quote.date}\nCheck or edit the RM amount below.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          rateFailed = true;
          message =
              'Printed total: $code $original. Rate unavailable. Retry or enter the RM amount yourself.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final store = ExpenseScope.of(context);
        store.transactions.requireIncome(date);
      final repo = store.repository;
      if (repo is! ReceiptRepository) {
        throw StateError('Receipt storage unavailable');
      }
      final receiptRepo = repo as ReceiptRepository;
      final value = double.parse(amount.text.trim());
      final candidates = await receiptRepo.receiptCandidates(date, value);
      if (!mounted) return;
      final matches = possibleReceiptDuplicates(
        candidates,
        merchant: merchant.text.trim(),
        date: date,
        amount: value,
        receiptPath: receiptPath,
      );
      if (matches.isNotEmpty &&
          !await confirmDuplicateReceipt(context, matches)) {
        return;
      }
      if (!mounted) return;
      receiptPath = await receiptRepo.uploadReceipt(receiptKey, photo!);
      if (!mounted) return;
      await store.save(
        description: description.text.trim(),
        amount: double.parse(amount.text.trim()),
        date: date,
        category: category,
        income: false,
        receiptPath: receiptPath,
        merchant: merchant.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receipt expense added.')));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    merchant.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(photo == null ? 'Scan receipt' : 'Receipt summary'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!supported)
              const Text('Receipt scanning is available on Android and iOS.')
            else ...[
              const Text(
                'Take a clear photo of the receipt, including the total, or choose a receipt photo.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : () => scan(ImageSource.camera),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Take photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => scan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose photo'),
                  ),
                ],
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              if (photo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            photo!,
                            width: 80,
                            height: 112,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 80,
                              child: Icon(Icons.receipt_long),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                busy
                                    ? Icons.hourglass_top
                                    : Icons.receipt_long_outlined,
                                color: Colors.indigo,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                busy
                                    ? 'Reading receipt...'
                                    : 'Review your receipt',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check the amount and details before saving.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (message != null)
                Semantics(liveRegion: true, child: Text(message!)),
              if (photo != null)
                Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Text('Expense amount in RM'),
                      const SizedBox(height: 8),
                      TextFormField(
                        enabled: !busy,
                        controller: amount,
                        decoration: const InputDecoration(
                          prefixText: 'RM ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          errorMaxLines: 3,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => AccountSetup.validateMoney(v),
                      ),
                      const SizedBox(height: 20),
                      const Text('Expense category'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey((photo, category)),
                        initialValue: category,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        isExpanded: true,
                        items: expenseCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() {
                                category = v!;
                                categoryGuidance =
                                    'Your selected category will be saved.';
                              }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        categoryGuidance,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (printedTotal != null) ...[
                        const SizedBox(height: 20),
                        const Text('Receipt currency'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey((photo, currency)),
                          initialValue: currency,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          isExpanded: true,
                          items: receiptCurrencies
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: busy
                              ? null
                              : (value) {
                                  if (value != null) convert(value);
                                },
                        ),
                      ],
                      if (rateFailed)
                        TextButton(
                          onPressed: busy ? null : () => convert(currency!),
                          child: const Text('Retry conversion'),
                        ),
                      const SizedBox(height: 20),
                      const Text('Merchant / shop name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: merchant,
                        enabled: !busy,
                        maxLength: 150,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          helperText: 'Check the shop name to help detect duplicate receipts.',
                          helperMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Description'),
                      const SizedBox(height: 8),
                      TextFormField(
                        enabled: !busy,
                        controller: description,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          errorMaxLines: 3,
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Enter a description'
                            : null,
                      ),
                      ListTile(
                        title: const Text('Expense date'),
                        subtitle: Text(dateLabel(date)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: busy
                            ? null
                            : () async {
                                final value = await showDatePicker(
                                  context: context,
                                  initialDate: date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (mounted && value != null) {
                                  setState(() => date = value);
                                }
                              },
                      ),
                      AbsorbPointer(
                        absorbing: busy,
                        child: AsyncButton(
                          label: 'Add expense',
                          onPressed: save,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => scan(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Scan again'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
