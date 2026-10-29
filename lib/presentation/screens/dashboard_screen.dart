import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/app_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/live_transaction_tile.dart';
import '../widgets/category_summary.dart';
import '../widgets/finance_charts.dart';
import 'income_screen.dart';
import 'transaction_form_screen.dart';
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
              const Text('Recorded cash flow'),
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
              const SizedBox(height: 12),
              const Text(
                'Income minus expenses. Your budget is a spending limit, not income.',
              ),
              if (store.income == 0 && store.expense > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'No received income recorded this month. Add income when you receive it.',
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const TransactionFormScreen(income: true),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Manage Income'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Income')),
                          body: const SafeArea(child: IncomeScreen()),
                        ),
                      ),
                    ),
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
              Text(
                store.remaining < 0
                    ? '${money(-store.remaining)} over budget'
                    : '${money(store.remaining)} budget remaining',
              ),
              const SizedBox(height: 6),
              Text(
                store.remaining < 0
                    ? 'Spending exceeds your budget.'
                    : store.remaining == 0
                    ? 'You have used your full budget.'
                    : 'Your spending is within budget.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: CashFlowChart(income: store.income, expense: store.expense),
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
          (e) => CategorySummary(
            category: e.key,
            amount: e.value,
            total: store.expense,
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
