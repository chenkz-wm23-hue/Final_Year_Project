import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../business_logic/account_setup.dart';
import '../../business_logic/receipt_reader.dart';
import '../../business_logic/receipt_exchange.dart';
import '../state/expense_store.dart';
import '../widgets/async_button.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key, this.picker});
  final ImagePicker? picker;
  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  late final picker = widget.picker ?? ImagePicker();
  final amount = TextEditingController();
  final description = TextEditingController(text: 'Receipt expense');
  final form = GlobalKey<FormState>();
  Uint8List? photo;
  String? message;
  String? printedTotal;
  String? currency;
  bool rateFailed = false;
  bool busy = false;
  String category = 'Others';
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
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        photo = bytes;
        printedTotal = null;
        currency = null;
        rateFailed = false;
        message = null;
        amount.clear();
        description.text = 'Receipt expense';
        category = 'Others';
        date = DateTime.now();
      });
      final receipt = await readReceipt(file.path);
      final total = receipt.total;
      if (!mounted) return;
      final suggested = ExpenseScope.of(context)
          .suggestReceiptCategory(receipt.lines);
      setState(() {
        printedTotal = total;
        category = expenseCategories.contains(suggested) ? suggested : 'Others';
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
      await ExpenseScope.of(context).save(
        description: description.text.trim(),
        amount: double.parse(amount.text.trim()),
        date: date,
        category: category,
        income: false,
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
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Scan receipt')),
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
                    label: Text(photo == null ? 'Take photo' : 'Scan again'),
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
                  child: Image.memory(
                    photo!,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Text('Preview unavailable'),
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
                      Text(
                        'Receipt summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey((photo, category)),
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Expense category',
                        ),
                        items: expenseCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() => category = v!),
                      ),
                      if (printedTotal != null)
                        DropdownButtonFormField<String>(
                          key: ValueKey((photo, currency)),
                          initialValue: currency,
                          decoration: const InputDecoration(
                            labelText: 'Receipt currency',
                          ),
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
                      if (rateFailed)
                        TextButton(
                          onPressed: busy ? null : () => convert(currency!),
                          child: const Text('Retry conversion'),
                        ),
                      TextFormField(
                        enabled: !busy,
                        controller: amount,
                        decoration: const InputDecoration(
                          labelText: 'Expense amount in RM',
                          prefixText: 'RM ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => AccountSetup.validateMoney(v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        enabled: !busy,
                        controller: description,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Description',
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
