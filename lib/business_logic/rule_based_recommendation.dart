import '../data/models/recommendation.dart';
import 'dashboard_calculation.dart';

class RuleBasedRecommendation {
  const RuleBasedRecommendation();
  List<Recommendation> generate(DashboardSummary s) {
    final result = <Recommendation>[];
    for (final category in ['Food', 'Shopping']) {
      final amount = s.categoryTotals[category] ?? 0;
      final threshold = category == 'Food' ? .4 : .3;
      if (s.expense > 0 && amount / s.expense >= threshold) {
        result.add(
          Recommendation(
            title: 'Review your ${category.toLowerCase()} spending',
            description:
                '$category accounts for ${(amount / s.expense * 100).toStringAsFixed(0)}% of expenses. Consider setting a limit for this category.',
            label: category,
          ),
        );
      }
    }
    if (s.ratio >= .8) {
      result.add(
        Recommendation(
          title: s.ratio >= 1
              ? 'Revisit your monthly plan'
              : 'Plan your remaining expenses',
          description: s.remaining < 0
              ? 'Expenses exceed your budget by RM ${(-s.remaining).toStringAsFixed(2)}. Review upcoming purchases.'
              : 'You have RM ${s.remaining.toStringAsFixed(2)} left in your monthly budget.',
          label: 'Budget',
        ),
      );
    }
    if (s.balance > 0) {
      result.add(
        Recommendation(
          title: 'Consider setting some money aside',
          description:
              'Income exceeds expenses by RM ${s.balance.toStringAsFixed(2)}. Account for upcoming bills before choosing an amount to save.',
          label: 'Monthly balance',
        ),
      );
    }
    return result;
  }
}
