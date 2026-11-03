import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/expense_store.dart';

/// Both bars share a zero baseline and the same scale for the selected month.
class CashFlowChart extends StatelessWidget {
  const CashFlowChart({super.key, required this.income, required this.expense});
  final double income, expense;

  @override
  Widget build(BuildContext context) {
    final maximum = math.max(income, expense);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income vs expenses',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        for (final row in [
          (label: 'Received income', value: income, color: Colors.teal),
          (
            label: 'Recorded expenses',
            value: expense,
            color: Colors.deepOrange,
          ),
        ]) ...[
          Text('${row.label} · ${money(row.value)}'),
          const SizedBox(height: 6),
          Semantics(
            label: '${row.label}: ${money(row.value)}',
            child: LayoutBuilder(
              builder: (_, constraints) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 22,
                  width: maximum == 0
                      ? 0
                      : constraints.maxWidth * row.value / maximum,
                  decoration: BoxDecoration(
                    color: row.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (maximum == 0)
          const Text('No income or expenses recorded this month.'),
      ],
    );
  }
}

class BudgetChart extends StatelessWidget {
  const BudgetChart({super.key, required this.spent, required this.budget});
  final double spent, budget;

  @override
  Widget build(BuildContext context) {
    final ratio = budget > 0 ? spent / budget : 0.0;
    final over = spent > budget;
    final color = over ? Theme.of(context).colorScheme.error : Colors.indigo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget usage', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 18),
        Center(
          child: Semantics(
            label: '${(ratio * 100).toStringAsFixed(0)} percent of budget used',
            child: SizedBox.square(
              dimension: 164,
              child: CustomPaint(
                painter: _BudgetRing(ratio.clamp(0, 1).toDouble(), color),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(ratio * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _legend('Spent', money(spent), color),
        _legend(
          'Available budget',
          money(math.max(0, budget - spent)),
          const Color(0xffdedcf4),
        ),
        if (over) _legend('Over budget', money(spent - budget), color),
      ],
    );
  }

  Widget _legend(String label, String amount, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, right: 8),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        Expanded(child: Text('$label · $amount')),
      ],
    ),
  );
}

class _BudgetRing extends CustomPainter {
  const _BudgetRing(this.fraction, this.color);
  final double fraction;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(10);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawOval(rect, paint..color = const Color(0xffdedcf4));
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BudgetRing oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
