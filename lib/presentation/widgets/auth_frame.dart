import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthFrame extends StatelessWidget {
  final String illustration, title, subtitle, action, footer, link;
  final List<Widget> fields;
  final VoidCallback onAction;
  final void Function(BuildContext) onLink;
  const AuthFrame({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.action,
    required this.onAction,
    required this.footer,
    required this.link,
    required this.onLink,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0FF),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    illustration,
                    style: const TextStyle(fontSize: 56),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: appInk,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: appMuted),
                ),
                const SizedBox(height: 31),
                ...fields,
                if (action == 'Login')
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: appIndigo,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: appIndigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => onLink(context),
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      text: footer,
                      style: const TextStyle(color: appMuted),
                      children: [
                        TextSpan(
                          text: link,
                          style: const TextStyle(
                            color: appIndigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
