import 'package:flutter/material.dart';

import '../../business_logic/account_setup.dart';
import '../state/expense_store.dart';
import 'async_button.dart';

class SavingGoalDialog extends StatefulWidget {
  const SavingGoalDialog({
    super.key,
    required this.metadata,
    required this.expectedIncome,
    required this.budget,
    required this.onSave,
  });

  final Map<String, dynamic> metadata;
  final double expectedIncome;
  final double budget;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<SavingGoalDialog> createState() => _SavingGoalDialogState();
}

class _SavingGoalDialogState extends State<SavingGoalDialog> {
  late final TextEditingController goalName;
  late final TextEditingController goalAmount;
  late final TextEditingController monthlySaving;
  final form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    goalName = TextEditingController(
      text: widget.metadata['saving_goal_name'] as String? ?? '',
    );
    goalAmount = TextEditingController(
      text:
          (widget.metadata['saving_goal_amount'] as num?)?.toStringAsFixed(2) ??
          '',
    );
    monthlySaving = TextEditingController(
      text:
          ((widget.metadata['monthly_saving_amount'] as num?)?.toDouble() ??
                  (widget.expectedIncome - widget.budget).clamp(
                    0,
                    double.infinity,
                  ))
              .toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    // The route may still render during its exit animation after Navigator.pop.
    goalName.dispose();
    goalAmount.dispose();
    monthlySaving.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = AccountSetup.monthsToReachGoal(
      goalAmount: double.tryParse(goalAmount.text) ?? 0,
      monthlySaving: double.tryParse(monthlySaving.text) ?? 0,
    );
    return AlertDialog(
      scrollable: true,
      title: const Text('Set saving goal'),
      content: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.expectedIncome > 0) ...[
              Text('Expected monthly income: ${money(widget.expectedIncome)}'),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: goalName,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Saving goal',
                hintText: 'e.g. New laptop',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a saving goal'
                  : null,
            ),
            TextFormField(
              controller: goalAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Goal amount',
                prefixText: 'RM ',
              ),
              validator: (value) => AccountSetup.validateMoney(value),
              onChanged: (_) => setState(() {}),
            ),
            TextFormField(
              controller: monthlySaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly saving amount',
                prefixText: 'RM ',
              ),
              validator: (value) => AccountSetup.validateMoney(value),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reserve this amount each month, starting this month. It reduces available money, not recorded income or expenses. Monthly allocations refresh when you open the app, including missed months. Editing updates this month’s allocation; earlier months stay unchanged.',
            ),
            const SizedBox(height: 12),
            Text(
              months == null
                  ? 'Enter positive amounts to calculate your timeline.'
                  : 'From zero, this plan takes $months monthly ${months == 1 ? 'allocation' : 'allocations'}. Progress is shown after saving.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AsyncButton(
          label: 'Save goal',
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            await widget.onSave({
              'saving_goal_name': goalName.text.trim(),
              'saving_goal_amount': double.parse(goalAmount.text),
              'monthly_saving_amount': double.parse(monthlySaving.text),
            });
            if (context.mounted) Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}
