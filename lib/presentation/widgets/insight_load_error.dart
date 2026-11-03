import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import 'async_button.dart';

class InsightLoadError extends StatelessWidget {
  const InsightLoadError({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text(
        'Saved insights could not be loaded. Check your connection and retry.',
      ),
      AsyncButton(
        label: 'Retry',
        onPressed: ExpenseScope.of(context).refreshInsights,
      ),
    ],
  );
}
