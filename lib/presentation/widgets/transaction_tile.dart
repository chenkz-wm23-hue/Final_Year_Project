import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TransactionTile extends StatelessWidget {
  final String emoji, title, subtitle, amount;
  final Color color;
  final bool income;
  const TransactionTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    this.income = false,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: CircleAvatar(
      backgroundColor: color,
      child: Text(emoji, style: const TextStyle(fontSize: 17)),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: appInk,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 11, color: appMuted),
    ),
    trailing: Text(
      amount,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: income ? const Color(0xFF1BB876) : const Color(0xFFF04D56),
      ),
    ),
  );
}
