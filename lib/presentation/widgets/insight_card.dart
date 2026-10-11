import 'package:flutter/material.dart';

import 'app_card.dart';

class InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, description, label;
  const InsightCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
