import 'package:flutter/material.dart';

import '../state/expense_store.dart';
import '../widgets/live_transaction_tile.dart';

class IncomeHistoryScreen extends StatefulWidget {
  const IncomeHistoryScreen({super.key});
  @override
  State<IncomeHistoryScreen> createState() => _IncomeHistoryScreenState();
}

class _IncomeHistoryScreenState extends State<IncomeHistoryScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final entries =
        ExpenseScope.of(context).entries
            .where(
              (entry) =>
                  entry.income &&
                  '${entry.description} ${entry.category} ${dateLabel(entry.date)}'
                      .toLowerCase()
                      .contains(query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) {
            final order = b.date.compareTo(a.date);
            return order != 0 ? order : b.id.compareTo(a.id);
          });
    return Scaffold(
      appBar: AppBar(title: const Text('Income history')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search income history',
                  hintText: 'Description, category or date',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'All months - newest first. Tap an entry to edit it.',
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No income history found.'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: entries.length,
                      itemBuilder: (_, index) =>
                          LiveTransactionTile(entry: entries[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
