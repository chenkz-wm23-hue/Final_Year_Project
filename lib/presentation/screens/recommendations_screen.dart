import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/month_selector.dart';
import '../widgets/insight_card.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    final recommendations = store.recommendations;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        const MonthSelector(),
        const SizedBox(height: 16),
        if (recommendations.isEmpty)
          const Text(
            'Record income and expenses to get spending recommendations.',
          ),
        ...recommendations.map(
          (r) => InsightCard(
            icon: Icons.lightbulb_outline,
            color: Colors.indigo,
            title: r.title,
            description: r.description,
            label: r.label,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Suggestions are based on simple spending rules for the selected month.',
        ),
      ],
    );
  }
}
