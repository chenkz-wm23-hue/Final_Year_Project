import 'package:flutter/material.dart';

import '../state/expense_store.dart';

/// Stacks labels and totals so large amounts and text scales can wrap.
class CategorySummary extends StatelessWidget {
  const CategorySummary({
    super.key,
    required this.category,
    required this.amount,
    required this.total,
  });
  final String category;
  final double amount, total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          '${money(amount)} · ${total > 0 ? (amount / total * 100).toStringAsFixed(0) : 0}%',
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total > 0 ? (amount / total).clamp(0, 1).toDouble() : 0,
        ),
      ],
    ),
  );
}
