import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/repositories/receipt_repository.dart';
import '../state/expense_store.dart';

class ReceiptViewerScreen extends StatefulWidget {
  const ReceiptViewerScreen({super.key, required this.entry});
  final TransactionEntry entry;
  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  Future<Uint8List>? image;
  Object? repository;
  Future<Uint8List> load() {
    final repo = ExpenseScope.of(context).repository;
    if (repo is! ReceiptRepository || widget.entry.receiptPath == null) {
      return Future.error(StateError('No receipt attached'));
    }
    return (repo as ReceiptRepository).downloadReceipt(
      widget.entry.receiptPath!,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = ExpenseScope.of(context).repository;
    if (!identical(repo, repository)) {
      repository = repo;
      image = load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Receipt attachment')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${widget.entry.merchant ?? widget.entry.description} • ${dateLabel(widget.entry.date)} • ${money(widget.entry.amount)}',
            ),
          ),
          const Text('Pinch to zoom'),
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: image,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Could not load this receipt. Check your connection and try again.',
                          ),
                          OutlinedButton(
                            onPressed: () => setState(() => image = load()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return InteractiveViewer(
                  minScale: .5,
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Text('Receipt preview unavailable.'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
