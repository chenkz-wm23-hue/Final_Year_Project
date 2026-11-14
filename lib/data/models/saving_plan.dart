import 'dart:math' as math;

class SavingPlan {
  const SavingPlan({
    required this.name,
    required this.target,
    required this.monthlyAmount,
    required this.allocations,
  });
  final String name;
  final double target, monthlyAmount;
  final Map<DateTime, double> allocations;
  double get allocated => allocations.values.fold(0, (a, b) => a + b);
  double get remaining => math.max(0, target - allocated);
  int get monthsRemaining => monthlyAmount > 0
      ? ((remaining * 100).round() / (monthlyAmount * 100).round()).ceil()
      : 0;
  double forMonth(DateTime month) =>
      allocations[DateTime(month.year, month.month)] ?? 0;
  Map<String, dynamic> get metadata => {
    'saving_goal_name': name,
    'saving_goal_amount': target,
    'monthly_saving_amount': monthlyAmount,
  };
}
