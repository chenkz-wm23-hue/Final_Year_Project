import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/month_selector.dart';
import '../widgets/insight_card.dart';
import '../widgets/insight_load_error.dart';

class RiskAlertsScreen extends StatelessWidget {
  const RiskAlertsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    final alerts = store.riskAlerts;
    return RefreshIndicator(
      onRefresh: store.refreshInsights,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          const MonthSelector(),
          const SizedBox(height: 16),
          if (store.insightsUnavailable) const InsightLoadError(),
          if (!store.insightsUnavailable && alerts.isEmpty)
            InsightCard(
              icon: Icons.check_circle_outline,
              color: Colors.teal,
              title: store.monthly.isEmpty
                  ? 'No activity this month'
                  : 'No spending alerts',
              description: store.monthly.isEmpty
                  ? 'Add income and expenses to see your spending status.'
                  : 'Your recorded spending has not triggered current budget or cash flow alerts.',
              label: store.monthLabel,
            ),
          ...alerts.map(
            (a) => InsightCard(
              icon: Icons.warning_amber_rounded,
              color: a.severity == RiskSeverity.high
                  ? Colors.red
                  : Colors.orange,
              title: a.title,
              description: a.description,
              label: a.label,
            ),
          ),
          const Text(
            'Alerts use your recorded transactions and budget; they are not predictions.',
          ),
        ],
      ),
    );
  }
}
