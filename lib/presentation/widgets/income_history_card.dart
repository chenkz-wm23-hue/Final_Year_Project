import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../screens/income_history_screen.dart';
import 'app_card.dart';
import 'live_transaction_tile.dart';

class IncomeHistoryCard extends StatelessWidget {
  const IncomeHistoryCard({super.key});
  @override
  Widget build(BuildContext context) {
    final entries =
        ExpenseScope.of(context).entries.where((entry) => entry.income).toList()
          ..sort((a, b) {
            final order = b.date.compareTo(a.date);
            return order != 0 ? order : b.id.compareTo(a.id);
          });
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Income history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncomeHistoryScreen(),
                  ),
                ),
                child: const Text('View history'),
              ),
            ],
          ),
          const Text('Latest income across all months'),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No income recorded yet. Add income to start your history.',
              ),
            ),
          ...entries
              .take(3)
              .map(
                (entry) => Material(
                  type: MaterialType.transparency,
                  child: LiveTransactionTile(entry: entry),
                ),
              ),
        ],
      ),
    );
  }
}
