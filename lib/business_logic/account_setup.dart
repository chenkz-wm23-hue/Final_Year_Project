import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/expense_repository.dart';
import 'budget_management.dart';

/// Preferences only: metadata is never used as an authorization decision.
class AccountSetup {
  const AccountSetup(this.client);
  final SupabaseClient client;
  bool get required {
    final user = client.auth.currentUser;
    if (user == null) return false;
    final metadata = user.userMetadata;
    // Missing flags are an unfinished setup, not permission to skip it.
    return metadata?['onboarding_required'] == true ||
        (metadata?['onboarding_completed'] != true &&
            metadata?['onboarding_skipped'] != true);
  }

  Future<void> skip() async {
    if (client.auth.currentUser == null) {
      throw StateError('Please log in again');
    }
    await client.auth.updateUser(
      UserAttributes(
        data: {'onboarding_required': false, 'onboarding_skipped': true},
      ),
    );
  }

  static String? validateMoney(String? input, {bool allowZero = false}) {
    final text = input?.trim() ?? '';
    final value = double.tryParse(text);
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text) ||
        value == null ||
        !value.isFinite ||
        value > 9999999999.99 ||
        (allowZero ? value < 0 : value <= 0)) {
      return allowZero
          ? 'Enter 0 or more, with up to 2 decimal places (max 9,999,999,999.99)'
          : 'Enter a positive amount with up to 2 decimal places (max 9,999,999,999.99)';
    }
    return null;
  }

  /// The automatic plan keeps 80% of expected income available for spending
  /// and reserves the remaining 20% for a saving goal.
  static double suggestedBudget(double income) =>
      (income * .8 * 100).roundToDouble() / 100;

  static int? monthsToReachGoal({
    required double goalAmount,
    required double monthlySaving,
  }) {
    if (goalAmount <= 0 || monthlySaving <= 0) return null;
    return (goalAmount / monthlySaving).ceil();
  }

  Future<void> complete(
    ExpenseRepository repository,
    DateTime month,
    String income,
    String budget, {
    String? savingGoalName,
    String? savingGoalAmount,
  }) async {
    if (validateMoney(income, allowZero: true) != null ||
        validateMoney(budget) != null) {
      throw ArgumentError('Invalid setup amounts');
    }
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Please log in again');
    // Upsert is safe to retry if the metadata request subsequently fails.
    await BudgetManagement(repository).save(month, double.parse(budget.trim()));
    if (client.auth.currentUser?.id != user.id) {
      throw StateError('Account changed');
    }
    await client.auth.updateUser(
      UserAttributes(
        data: {
          'expected_monthly_income': double.parse(income.trim()),
          if (savingGoalName != null && savingGoalName.trim().isNotEmpty)
            'saving_goal_name': savingGoalName.trim(),
          if (savingGoalAmount != null && savingGoalAmount.trim().isNotEmpty)
            'saving_goal_amount': double.parse(savingGoalAmount.trim()),
          if (savingGoalName != null && savingGoalName.trim().isNotEmpty)
            'monthly_saving_amount':
                double.parse(income.trim()) - double.parse(budget.trim()),
          'onboarding_required': false,
          'onboarding_completed': true,
          'onboarding_skipped': false,
        },
      ),
    );
  }
}
