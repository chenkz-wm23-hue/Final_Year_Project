import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final bool obscure;
  const AppField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: appInk,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFAEB0BF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF9296A9), size: 21),
            suffixIcon: obscure
                ? const Icon(
                    Icons.visibility_off_outlined,
                    color: Color(0xFF9296A9),
                    size: 20,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE1E2EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE1E2EB)),
            ),
          ),
        ),
      ],
    ),
  );
}
