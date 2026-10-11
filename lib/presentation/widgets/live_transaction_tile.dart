import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../screens/transaction_form_screen.dart';

class LiveTransactionTile extends StatelessWidget {
  final TransactionEntry entry;
  const LiveTransactionTile({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(entry.income ? Icons.south_west : Icons.north_east),
      ),
      title: Text(entry.description),
      subtitle: Text('${entry.category} · ${dateLabel(entry.date)}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TransactionFormScreen(income: entry.income, entry: entry),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${entry.income ? '+' : '-'}${money(entry.amount)}',
            style: TextStyle(
              color: entry.income ? Colors.teal : Colors.deepOrange,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Transaction actions',
            onSelected: (value) async {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionFormScreen(
                      income: entry.income,
                      entry: entry,
                    ),
                  ),
                );
                return;
              }
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete transaction?'),
                  content: Text(
                    'Remove ${entry.description} from your transactions?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) store.delete(entry.id);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
