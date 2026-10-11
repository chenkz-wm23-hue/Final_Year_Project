import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [appIndigo, Color(0xFF665BEE)]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Total Balance', style: TextStyle(color: Color(0xFFDAD8FF))),
            Spacer(),
            Icon(Icons.visibility_outlined, color: Colors.white70),
          ],
        ),
        SizedBox(height: 12),
        Text(
          'RM 1,250.00',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'This month⌄',
            style: TextStyle(color: Color(0xFFE2E1FF), fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class MiniStat extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const MiniStat(this.title, this.value, this.icon, this.color, {super.key});
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: appMuted, fontSize: 11),
              ),
            ),
            CircleAvatar(
              radius: 11,
              backgroundColor: color.withValues(alpha: .13),
              child: Icon(icon, size: 14, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: appInk,
          ),
        ),
      ],
    ),
  );
}

class BudgetProgress extends StatelessWidget {
  const BudgetProgress({super.key});
  @override
  Widget build(BuildContext context) => AppCard(
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Monthly Budget',
              style: TextStyle(fontWeight: FontWeight.w800, color: appInk),
            ),
            Spacer(),
            Text(
              '63%',
              style: TextStyle(fontWeight: FontWeight.w800, color: appIndigo),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          'RM 1,500.00',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 11),
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          child: LinearProgressIndicator(
            value: .63,
            minHeight: 8,
            backgroundColor: Color(0xFFE5E7EF),
            color: Color(0xFF20BA7A),
          ),
        ),
        SizedBox(height: 9),
        Row(
          children: [
            Text(
              'RM 950.00 spent',
              style: TextStyle(color: appMuted, fontSize: 11),
            ),
            Spacer(),
            Text(
              'RM 550.00 left',
              style: TextStyle(color: appMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class SpendingCard extends StatelessWidget {
  const SpendingCard({super.key});
  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        SizedBox(
          width: 126,
          height: 126,
          child: CustomPaint(painter: DonutPainter()),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            children: [
              Legend('Food', '40%', 'RM 500.00', Color(0xFFF04D56)),
              Legend('Shopping', '25%', 'RM 312.50', Color(0xFFFF9F18)),
              Legend('Transport', '15%', 'RM 187.50', Color(0xFF4385E6)),
              Legend('Others', '20%', 'RM 250.00', Color(0xFF35BF79)),
            ],
          ),
        ),
      ],
    ),
  );
}

class Legend extends StatelessWidget {
  final String name, pct, amount;
  final Color color;
  const Legend(this.name, this.pct, this.amount, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, color: appInk),
          ),
        ),
        Text(pct, style: const TextStyle(fontSize: 11, color: appMuted)),
        const SizedBox(width: 8),
        Text(
          amount,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class DonutPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.butt;
    double a = -1.57;
    for (final x in [
      (0.4, const Color(0xFFF04D56)),
      (.25, const Color(0xFFFF9F18)),
      (.15, const Color(0xFF4385E6)),
      (.2, const Color(0xFF35BF79)),
    ]) {
      p.color = x.$2;
      final sweep = x.$1 * 6.283 - 0.055;
      c.drawArc(rect.deflate(10), a, sweep, false, p);
      a += sweep + .055;
    }
    final t = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'RM 1,250\n',
            style: TextStyle(
              color: appInk,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'Total',
            style: TextStyle(color: appMuted, fontSize: 10),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, Offset((s.width - t.width) / 2, (s.height - t.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
