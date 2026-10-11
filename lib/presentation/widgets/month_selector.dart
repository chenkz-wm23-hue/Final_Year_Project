import 'package:flutter/material.dart';

import '../state/expense_store.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () => store.changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            store.monthLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: () => store.changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
