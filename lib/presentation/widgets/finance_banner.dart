import 'package:flutter/material.dart';

class FinanceBanner extends StatelessWidget {
  const FinanceBanner({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
  });
  final String title, value;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff7254f5), Color(0xff5141d7)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!)],
        ],
      ),
    ),
  );
}
