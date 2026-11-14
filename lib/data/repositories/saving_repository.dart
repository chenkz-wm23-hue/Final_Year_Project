import '../models/saving_plan.dart';

abstract interface class SavingRepository {
  SavingPlan? get savingPlan;
  Future<void> refreshSavings();
  Future<void> saveSavingGoal(String name, double target, double monthly);
}
