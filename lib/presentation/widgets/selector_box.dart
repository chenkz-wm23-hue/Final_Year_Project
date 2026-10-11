import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SelectorBox extends StatelessWidget {
  final String text;
  const SelectorBox(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE1E2EB)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 14, color: appInk)),
        const Spacer(),
        const Icon(Icons.keyboard_arrow_down, color: appMuted),
      ],
    ),
  );
}
