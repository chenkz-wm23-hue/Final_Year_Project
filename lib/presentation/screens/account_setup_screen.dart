import 'package:flutter/material.dart';

import '../../business_logic/account_setup.dart';
import '../widgets/async_button.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({
    super.key,
    required this.monthLabel,
    required this.onComplete,
    required this.onSignOut,
  });
  final String monthLabel;
  final Future<void> Function(
    String income,
    String budget,
    String? savingGoalName,
    String? savingGoalAmount,
  ) onComplete;
  final Future<void> Function() onSignOut;
  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final form = GlobalKey<FormState>();
  final income = TextEditingController();
  final budget = TextEditingController();
  final savingGoalName = TextEditingController();
  final savingGoalAmount = TextEditingController();
  bool usingAutoAllocation = false;
  @override
  void dispose() {
    income.dispose();
    budget.dispose();
    savingGoalName.dispose();
    savingGoalAmount.dispose();
    super.dispose();
  }

  Future<void> askToAutoAllocate() async {
    final incomeAmount = double.tryParse(income.text.trim());
    if (incomeAmount == null || incomeAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your expected monthly income first.'),
        ),
      );
      return;
    }
    final shouldAllocate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-allocate your budget?'),
        content: Text(
          'Use an 80/20 plan? RM ${(incomeAmount * .8).toStringAsFixed(2)} will be your monthly spending budget and RM ${(incomeAmount * .2).toStringAsFixed(2)} will be reserved for savings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, I’ll set it myself'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use 80/20 plan'),
          ),
        ],
      ),
    );
    if (shouldAllocate == true && mounted) {
      setState(() {
        usingAutoAllocation = true;
        budget.text = AccountSetup.suggestedBudget(
          incomeAmount,
        ).toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set up your account')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.savings_outlined, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome! Let’s make a plan.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tell us your expected monthly income and choose a spending limit. You can enter 0 if you have no regular income.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: income,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Expected monthly income',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(),
                      errorMaxLines: 3,
                    ),
                    validator: (v) =>
                        AccountSetup.validateMoney(v, allowZero: true),
                    onChanged: (_) {
                      if (usingAutoAllocation) {
                        setState(() => usingAutoAllocation = false);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This is a planning estimate, not an income transaction. Record money received on the Income screen.',
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Monthly budget · ${widget.monthLabel}'),
                      TextButton.icon(
                        onPressed: askToAutoAllocate,
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Auto-allocate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: budget,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Spending limit',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(),
                      errorMaxLines: 3,
                    ),
                    validator: (v) => AccountSetup.validateMoney(v),
                    onChanged: (_) {
                      if (usingAutoAllocation) {
                        setState(() => usingAutoAllocation = false);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This limit applies to the month shown. You can update it on the Budget screen.',
                  ),
                  if (usingAutoAllocation) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'What are you saving for?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a goal to see how long your monthly savings will take.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: savingGoalName,
                      decoration: const InputDecoration(
                        labelText: 'Saving goal',
                        hintText: 'e.g. New laptop',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: savingGoalAmount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Goal amount',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return AccountSetup.validateMoney(value);
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    if (double.tryParse(savingGoalAmount.text) != null) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final incomeAmount =
                              double.tryParse(income.text) ?? 0;
                          final budgetAmount =
                              double.tryParse(budget.text) ?? 0;
                          final goalAmount =
                              double.tryParse(savingGoalAmount.text) ?? 0;
                          final months = AccountSetup.monthsToReachGoal(
                            goalAmount: goalAmount,
                            monthlySaving: incomeAmount - budgetAmount,
                          );
                          return Text(
                            months == null
                                ? 'Choose a positive goal and leave room for savings.'
                                : 'At RM ${(incomeAmount - budgetAmount).toStringAsFixed(2)} saved each month, you can reach this goal in about $months ${months == 1 ? 'month' : 'months'}.',
                          );
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  AsyncButton(
                    label: 'Finish setup',
                    onPressed: () async {
                      if (form.currentState!.validate()) {
                        await widget.onComplete(
                          income.text,
                          budget.text,
                          usingAutoAllocation ? savingGoalName.text : null,
                          usingAutoAllocation ? savingGoalAmount.text : null,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AsyncButton(label: 'Sign out', onPressed: widget.onSignOut),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
