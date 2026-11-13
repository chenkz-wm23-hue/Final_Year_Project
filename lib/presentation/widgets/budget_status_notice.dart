import 'package:flutter/material.dart';

import '../state/expense_store.dart';

class BudgetStatusNotice extends StatelessWidget {
  const BudgetStatusNotice({
    super.key,
    required this.spent,
    required this.budget,
  });
  final double spent, budget;
  @override
  Widget build(BuildContext context) {
    if (budget <= 0) {
      return const Text(
        'Set a monthly budget to track your remaining spending limit.',
      );
    }
    final exceeded = spent > budget;
    final warning = budget > 0 && spent >= budget * .8;
    final color = exceeded
        ? Colors.red.shade800
        : warning
        ? Colors.amber.shade900
        : Colors.teal.shade800;
    final text = exceeded
        ? '${money(spent - budget)} over budget. Review your expenses and reduce optional spending.'
        : spent == budget
        ? 'You have used your full budget. Review your spending before adding more expenses.'
        : warning
        ? 'You have used ${(spent / budget * 100).toStringAsFixed(0)}% of your budget. Plan your remaining ${money(budget - spent)} carefully.'
        : 'Your spending is within budget.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning || exceeded
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
