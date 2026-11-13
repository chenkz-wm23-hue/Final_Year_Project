import 'dart:typed_data';

import '../models/transaction.dart';

abstract interface class ReceiptRepository {
  Future<String> uploadReceipt(String key, Uint8List png);
  Future<Uint8List> downloadReceipt(String path);
  Future<List<TransactionEntry>> receiptCandidates(
    DateTime date,
    double amount,
  );
}
