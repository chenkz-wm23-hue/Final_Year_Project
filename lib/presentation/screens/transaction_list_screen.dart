import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/month_selector.dart';
import '../widgets/finance_banner.dart';
import '../widgets/live_transaction_tile.dart';
import 'transaction_form_screen.dart';
import 'income_history_screen.dart';

class TransactionListScreen extends StatefulWidget {
  final bool? income;
  const TransactionListScreen({super.key, this.income});
  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String query = '', filter = 'All';
  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    final entries = store.monthly
        .where(
          (e) =>
              (widget.income == null || e.income == widget.income) &&
              (filter == 'All' || e.income == (filter == 'Income')) &&
              ('${e.description} ${e.category}'.toLowerCase().contains(
                query.toLowerCase(),
              )),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        const MonthSelector(),
        if (widget.income == true)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Salary repeats each month. Edit this month’s salary to update the amount carried into the following month.',
            ),
          ),
        if (widget.income != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FinanceBanner(
              title: widget.income! ? 'Monthly income' : 'Monthly expenses',
              value: money(widget.income! ? store.income : store.expense),
              subtitle: store.monthLabel,
            ),
          ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search transactions',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 16),
        if (widget.income == null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in ['All', 'Income', 'Expense'])
                ChoiceChip(
                  label: Text(value),
                  selected: filter == value,
                  onSelected: (_) => setState(() => filter = value),
                ),
            ],
          ),
        if (widget.income != null)
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionFormScreen(income: widget.income!),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text('Add ${widget.income! ? 'Income' : 'Expense'}'),
          ),
        if (widget.income == true)
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomeHistoryScreen()),
            ),
            icon: const Icon(Icons.history),
            label: const Text('View income history'),
          ),
        const SizedBox(height: 20),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No transactions match this month and search.',
              textAlign: TextAlign.center,
            ),
          ),
        ...entries.map((e) => LiveTransactionTile(entry: e)),
      ],
    );
  }
}
