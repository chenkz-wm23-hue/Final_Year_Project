import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/app_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/live_transaction_tile.dart';
import 'transactions_screen.dart';
import 'recommendations_screen.dart';
import 'risk_alerts_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        Text(
          'Hi, ${store.name}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text('Your money at a glance'),
        const MonthSelector(),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Balance this month'),
              Text(
                money(store.balance),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  Text(
                    'Income\n${money(store.income)}',
                    style: const TextStyle(color: Colors.teal),
                  ),
                  Text(
                    'Expenses\n${money(store.expense)}',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly budget · ${money(store.budget)}'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: store.ratio.clamp(0, 1).toDouble(),
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Text('${money(store.remaining)} remaining'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Spending summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (store.expense == 0)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Add your first expense to see your spending summary.'),
          ),
        ...store.categoryTotals.entries.map(
          (e) => ListTile(
            title: Text(e.key),
            subtitle: LinearProgressIndicator(value: e.value / store.expense),
            trailing: Text(
              '${money(e.value)}\n${(e.value / store.expense * 100).toStringAsFixed(0)}%',
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Recommendations'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Recommendations')),
                    body: const RecommendationsScreen(),
                  ),
                ),
              ),
            ),
            ActionChip(
              label: const Text('Risk Alerts'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Risk Alerts')),
                    body: const RiskAlertsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent transactions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Transactions')),
                    body: const TransactionsScreen(),
                  ),
                ),
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        ...store.monthly.take(5).map((e) => LiveTransactionTile(entry: e)),
      ],
    );
  }
}
