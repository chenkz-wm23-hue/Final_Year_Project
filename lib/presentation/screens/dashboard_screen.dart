import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/app_card.dart';
import '../widgets/income_history_card.dart';
import '../widgets/budget_status_notice.dart';
import 'receipt_scan_screen.dart';
import '../widgets/backend_analytics_panel.dart';
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff7254f5), Color(0xff5141d7)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balance'),
                Text(
                  money(store.balance),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Text(
                      'Income\n${money(store.income)}',
                      style: const TextStyle(color: Color(0xffb9f6e5)),
                    ),
                    Text(
                      'Expenses\n${money(store.expense)}',
                      style: const TextStyle(color: Color(0xffffdbd0)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (store.savingPlan != null) ...[
                  Text('Reserved for goal · ${money(store.monthlySavings)}'),
                  Text(
                    'Available after savings · ${money(store.availableAfterSavings)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (store.availableAfterSavings < 0)
                    const Text(
                      'Recorded income does not cover expenses and planned savings.',
                    ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Income minus expenses. Your budget is a spending limit, not income.',
                ),
                if (store.income == 0 && store.expense > 0) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No received income recorded this month. Add income when you receive it.',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: const Text('Add Income'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionFormScreen(income: true),
                ),
              ),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionFormScreen(income: false),
                ),
              ),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Scan Receipt'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptScanScreen()),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
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
        ),
        const SizedBox(height: 16),
        const IncomeHistoryCard(),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.budget > 0
                    ? 'Monthly budget · ${money(store.budget)}'
                    : 'Monthly budget · Not set',
              ),
              const SizedBox(height: 12),
              BudgetChart(spent: store.expense, budget: store.budget),
              const SizedBox(height: 12),
              Text(
                store.budget <= 0
                    ? 'Choose your spending limit on the Budget screen.'
                    : store.remaining < 0
                    ? '${money(-store.remaining)} over budget'
                    : '${money(store.remaining)} budget remaining',
              ),
              const SizedBox(height: 6),
              BudgetStatusNotice(spent: store.expense, budget: store.budget),
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
        const SizedBox(height: 20),
        const BackendAnalyticsPanel(),
      ],
    );
  }
}
