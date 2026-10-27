import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/async_button.dart';

class TransactionFormScreen extends StatefulWidget {
  final bool income;
  final TransactionEntry? entry;
  const TransactionFormScreen({super.key, required this.income, this.entry});
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController description, amount;
  late DateTime date;
  late String category;
  bool manualCategory = false;
  @override
  void initState() {
    super.initState();
    description = TextEditingController(text: widget.entry?.description ?? '');
    amount = TextEditingController(
      text: widget.entry?.amount.toStringAsFixed(2) ?? '',
    );
    date = widget.entry?.date ?? DateTime.now();
    category = widget.entry?.category ?? (widget.income ? 'Salary' : 'Others');
    manualCategory = widget.entry != null;
  }

  @override
  void dispose() {
    description.dispose();
    amount.dispose();
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
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a description'
                    : null,
                onChanged: (v) {
                  if (!widget.income && !manualCategory) {
                    setState(() => category = store.suggestCategory(v));
                  }
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final number = double.tryParse(v ?? '');
                  return number == null || !number.isFinite || number <= 0
                      ? 'Enter an amount greater than zero'
                      : null;
                },
              ),
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
                  if (picked != null && mounted) setState(() => date = picked);
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
                  subtitle: const Text(
                    'Matches common merchant names and keywords.',
                  ),
                  value: !manualCategory,
                  onChanged: (v) => setState(() {
                    manualCategory = !v;
                    if (v) {
                      category = store.suggestCategory(description.text);
                    }
                  }),
                ),
              const SizedBox(height: 24),
              AsyncButton(
                label: 'Save $type',
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  await store.save(
                    id: widget.entry?.id,
                    description: description.text,
                    amount: double.parse(amount.text),
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
    );
  }
}
