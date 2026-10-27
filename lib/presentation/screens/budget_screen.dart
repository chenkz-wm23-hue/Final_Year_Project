import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/app_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/category_summary.dart';
import '../widgets/async_button.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Future<void> editBudget(ExpenseStore store) async {
    var amount = store.budget.toStringAsFixed(2);
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text('Budget · ${store.monthLabel}'),
        content: Form(
          key: form,
          child: TextFormField(
            autofocus: true,
            initialValue: amount,
            onChanged: (value) => amount = value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly limit',
              prefixText: 'RM ',
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || !n.isFinite || n <= 0
                  ? 'Enter a positive budget'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AsyncButton(
            label: 'Save',
            onPressed: () async {
              if (form.currentState!.validate()) {
                await store.setBudget(double.parse(amount));
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        const MonthSelector(),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly budget'),
              Text(
                money(store.budget),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text('Spent: ${money(store.expense)}'),
              Text(
                '${store.remaining >= 0 ? 'Remaining' : 'Over budget'}: ${money(store.remaining.abs())}',
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: store.ratio.clamp(0, 1).toDouble(),
                minHeight: 9,
                color: store.ratio >= 1 ? Colors.red : Colors.teal,
              ),
              const SizedBox(height: 10),
              Text('${(store.ratio * 100).toStringAsFixed(0)}% used'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => editBudget(store),
          child: const Text('Update Budget'),
        ),
        const SizedBox(height: 24),
        Text(
          store.ratio >= 1
              ? 'Budget exceeded. Review your spending.'
              : store.ratio >= .8
              ? 'You are approaching your budget limit.'
              : 'Your spending is within budget.',
        ),
        const SizedBox(height: 24),
        const Text(
          'Category breakdown',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        if (store.categoryTotals.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No expenses recorded this month.'),
          ),
        ...store.categoryTotals.entries.map(
          (e) => CategorySummary(
            category: e.key,
            amount: e.value,
            total: store.expense,
          ),
        ),
      ],
    );
  }
}
