import 'receipt_viewer_screen.dart';

import 'package:flutter/material.dart';

import '../../business_logic/receipt_exchange.dart';
import '../../business_logic/receipt_reader.dart' show receiptCurrencies;

import '../state/expense_store.dart';
import '../widgets/async_button.dart';
import '../../business_logic/category_suggestion.dart';
import '../../business_logic/account_setup.dart';

class TransactionFormScreen extends StatefulWidget {
  final bool income;
  final TransactionEntry? entry;
  final Future<ReceiptRate> Function(String)? rateLoader;
  const TransactionFormScreen({
    super.key,
    required this.income,
    this.entry,
    this.rateLoader,
  });
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController description, amount;
  late DateTime date;
  late String category;
  bool manualCategory = false;
  String currency = 'MYR';
  final convertedAmount = TextEditingController();
  String? conversionMessage;
  bool converting = false;
  int conversionRequest = 0;

  void invalidateConversion() {
    conversionRequest++;
    convertedAmount.clear();
    if (mounted) {
      setState(() {
        converting = false;
        conversionMessage = null;
      });
    }
  }

  Future<void> convertAmount() async {
    final error = AccountSetup.validateMoney(amount.text);
    if (error != null) {
      setState(() => conversionMessage = error);
      return;
    }
    final request = ++conversionRequest;
    final original = double.parse(amount.text.trim());
    final code = currency;
    setState(() {
      converting = true;
      conversionMessage = null;
    });
    try {
      final quote = await (widget.rateLoader ?? latestReceiptRate)(code);
      if (!mounted || request != conversionRequest) return;
      final result = original * quote.rate;
      if (!result.isFinite || result <= 0 || result > 9999999999.99) {
        throw const FormatException('Invalid converted amount');
      }
      setState(() {
        convertedAmount.text = result.toStringAsFixed(2);
        conversionMessage =
            '1 $code = RM ${quote.rate} • ${quote.date} (reference rate). Check or edit the RM amount before saving.';
      });
    } catch (_) {
      if (mounted && request == conversionRequest) {
        setState(() {
          conversionMessage =
              'Conversion unavailable. Retry or enter the RM amount yourself.';
        });
      }
    } finally {
      if (mounted && request == conversionRequest) {
        setState(() => converting = false);
      }
    }
  }

  CategorySuggestion? suggestion;
  @override
  void initState() {
    super.initState();
    description = TextEditingController(text: widget.entry?.description ?? '');
    amount = TextEditingController(
      text: widget.entry?.amount.toStringAsFixed(2) ?? '',
    );
    amount.addListener(invalidateConversion);
    date = widget.entry?.date ?? DateTime.now();
    category = widget.entry?.category ?? (widget.income ? 'Salary' : 'Others');
    manualCategory = widget.entry != null;
  }

  @override
  void dispose() {
    description.dispose();
    amount.removeListener(invalidateConversion);
    amount.dispose();
    convertedAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    final type = widget.income ? 'Income' : 'Expense';
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.entry == null ? 'Add' : 'Edit'} $type'),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    errorMaxLines: 3,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter a description'
                      : v.trim().length > 500
                      ? 'Keep the description within 500 characters'
                      : null,
                  onChanged: (v) {
                    if (!widget.income && !manualCategory) {
                      setState(() {
                        suggestion = store.categorySuggestion(v);
                        category = suggestion!.category;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: currency == 'MYR'
                        ? 'Amount'
                        : 'Amount ($currency)',
                    prefixText: currency == 'MYR' ? 'RM ' : '$currency ',
                    border: OutlineInputBorder(),
                    errorMaxLines: 3,
                  ),
                  validator: (v) {
                    final number = double.tryParse(v ?? '');
                    return number == null || !number.isFinite || number <= 0
                        ? 'Enter an amount greater than zero'
                        : AccountSetup.validateMoney(v);
                  },
                ),
                if (!widget.income) ...[
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const ValueKey('expenseCurrency'),
                        value: currency,
                        isExpanded: true,
                        items: receiptCurrencies
                            .map(
                              (code) => DropdownMenuItem(
                                value: code,
                                child: Text(
                                  code == 'MYR'
                                      ? 'MYR - Malaysian Ringgit'
                                      : code,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (code) {
                          if (code == null) return;
                          currency = code;
                          invalidateConversion();
                        },
                      ),
                    ),
                  ),
                  if (widget.entry != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Saved expenses are stored in RM. Choose another currency only to enter a new original amount.',
                      ),
                    ),
                  if (currency != 'MYR') ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: converting ? null : convertAmount,
                      icon: const Icon(Icons.currency_exchange),
                      label: Text(
                        converting ? 'Converting...' : 'Convert to RM',
                      ),
                    ),
                    if (conversionMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(conversionMessage!),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('convertedRmAmount'),
                      controller: convertedAmount,
                      enabled: !converting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount to save in RM',
                        prefixText: 'RM ',
                        helperText:
                            'All totals and budgets use this RM amount.',
                        helperMaxLines: 3,
                        errorMaxLines: 3,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => AccountSetup.validateMoney(value),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(dateLabel(date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && mounted) {
                      setState(() => date = picked);
                    }
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey(category),
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: widget.income ? 'Income source' : 'Category',
                    border: const OutlineInputBorder(),
                  ),
                  items: (widget.income ? incomeCategories : expenseCategories)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    category = v!;
                    manualCategory = true;
                  }),
                ),
                if (!widget.income)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Suggest category from description'),
                    subtitle: Text(
                      manualCategory
                          ? 'Your selected category will be saved.'
                          : suggestion == null
                          ? 'Suggest a category as you type. You can change it.'
                          : 'Suggested category - check before saving.',
                    ),
                    value: !manualCategory,
                    onChanged: (v) => setState(() {
                      manualCategory = !v;
                      if (v) {
                        suggestion = store.categorySuggestion(description.text);
                        category = suggestion!.category;
                      }
                    }),
                  ),
                if (widget.entry?.receiptPath != null)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReceiptViewerScreen(entry: widget.entry!),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View receipt'),
                  ),
                const SizedBox(height: 24),
                AsyncButton(
                  label: 'Save $type',
                  onPressed: () async {
                    if (converting || !form.currentState!.validate()) return;
                    await store.save(
                      id: widget.entry?.id,
                      description: description.text,
                      amount: double.parse(
                        (currency == 'MYR' ? amount.text : convertedAmount.text)
                            .trim(),
                      ),
                      date: date,
                      category: category,
                      income: widget.income,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$type saved for ${dateLabel(date)}'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
