import 'package:flutter/material.dart';

import '../state/expense_store.dart';

Future<bool> confirmDuplicateReceipt(
  BuildContext context,
  List<TransactionEntry> matches,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Possible duplicate receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An expense with a similar merchant, the same date and RM amount already exists. If the merchant is unknown, this warning uses date and amount only.',
            ),
            const SizedBox(height: 12),
            for (final entry in matches.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${entry.merchant ?? entry.description}\n${dateLabel(entry.date)} • ${money(entry.amount)}',
                ),
              ),
            const Text(
              'Check the existing expense before adding another copy.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add anyway'),
          ),
        ],
      ),
    ) ??
    false;
