import '../data/models/risk_alert.dart';
import 'dashboard_calculation.dart';

/// Current deterministic fallback, deliberately separate from the future ML API.
class RuleBasedRiskEvaluator {
  const RuleBasedRiskEvaluator();
  List<RiskAlert> evaluate(DashboardSummary s) {
    final result = <RiskAlert>[];
    if (s.ratio >= .8) {
      result.add(
        RiskAlert(
          title: s.ratio >= 1
              ? 'Monthly budget exceeded'
              : 'Approaching budget limit',
          description:
              'You have spent RM ${s.expense.toStringAsFixed(2)} of RM ${s.budget.toStringAsFixed(2)}.',
          label: '${(s.ratio * 100).toStringAsFixed(0)}% used',
          severity: s.ratio >= 1 ? RiskSeverity.high : RiskSeverity.warning,
        ),
      );
    }
    if (s.expense > s.income) {
      result.add(
        RiskAlert(
          title: 'Expenses exceed income',
          description:
              'Recorded expenses are RM ${(s.expense - s.income).toStringAsFixed(2)} above income this month.',
          label: 'Cash flow alert',
          severity: RiskSeverity.high,
        ),
      );
    }
    for (final e in s.categoryTotals.entries) {
      if (e.value >= s.budget * .5) {
        result.add(
          RiskAlert(
            title: 'High spending in ${e.key}',
            description:
                'RM ${e.value.toStringAsFixed(2)} uses ${(e.value / s.budget * 100).toStringAsFixed(0)}% of your monthly budget.',
            label: 'Category alert',
          ),
        );
      }
    }
    return result;
  }
}
