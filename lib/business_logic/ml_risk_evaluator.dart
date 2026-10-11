import '../data/models/risk_alert.dart';
import 'dashboard_calculation.dart';

/// Extension point for a future trained model. No ML model is currently loaded.
abstract interface class MlRiskEvaluator {
  Future<List<RiskAlert>> evaluate(DashboardSummary summary);
}
