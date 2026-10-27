import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    return 'Could not save your data. Please check your connection and try again.';
  }
  return 'Unable to complete the request. Check your connection and try again.';
}

class AsyncButton extends StatefulWidget {
  const AsyncButton({super.key, required this.label, required this.onPressed});
  final String label;
  final Future<void> Function() onPressed;
  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            try {
              await widget.onPressed();
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
              }
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
    child: Text(busy ? 'Please wait…' : widget.label),
  );
}
