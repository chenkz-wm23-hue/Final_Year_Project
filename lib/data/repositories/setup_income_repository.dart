abstract interface class SetupIncomeRepository {
  Future<void> recordSetupIncome(double amount, DateTime month);
}
