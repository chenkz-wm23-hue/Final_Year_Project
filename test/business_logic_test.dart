import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/business_logic/dashboard_calculation.dart';
import 'package:final_year_project/business_logic/rule_based_recommendation.dart';
import 'package:final_year_project/business_logic/rule_based_risk_evaluator.dart';
import 'package:final_year_project/business_logic/async_task_producer.dart';

void main() {
  test('budget warnings begin at 80 percent and clear below threshold', () {
    const evaluator = RuleBasedRiskEvaluator();
    expect(evaluator.evaluate(const DashboardSummary(income: 2000, expense: 799, budget: 1000, categoryTotals: {})), isEmpty);
    final alerts = evaluator.evaluate(const DashboardSummary(income: 2000, expense: 800, budget: 1000, categoryTotals: {}));
    expect(alerts.single.title, 'Approaching budget limit');
  });
  test('empty data does not generate recommendations or divide by zero', () {
    final summary = const DashboardCalculation().calculate([], 1500);
    expect(summary.balance, 0);
    expect(summary.categoryTotals, isEmpty);
    expect(const RuleBasedRecommendation().generate(summary), isEmpty);
  });
  test('async task boundary returns results and propagates failures', () async {
    const tasks = AsyncTaskProducer();
    expect(await tasks.submit(() => 42), 42);
    await expectLater(tasks.submit<void>(() => throw StateError('failed')), throwsStateError);
  });
}
