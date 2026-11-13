import '../data/models/transaction.dart';

String suggestReceiptMerchant(List<String> lines) {
  for (final raw in lines.take(8)) {
    final line = raw.trim();
    if (line.length < 2 ||
        line.length > 150 ||
        !RegExp(r'[a-zA-Z]').hasMatch(line)) {
      continue;
    }
    if (RegExp(
      r'^(receipt|invoice|tax invoice|reprint receipt|welcome|thank you|tel|date|time|cashier|table|total)\b',
      caseSensitive: false,
    ).hasMatch(line)) {
      continue;
    }
    return line;
  }
  return '';
}

String _normal(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

List<TransactionEntry> possibleReceiptDuplicates(
  Iterable<TransactionEntry> entries, {
  required String merchant,
  required DateTime date,
  required double amount,
  String? receiptPath,
}) {
  final name = _normal(merchant);
  return entries.where((entry) {
    if (entry.income ||
        (receiptPath != null && entry.receiptPath == receiptPath)) {
      return false;
    }
    if (entry.date.year != date.year ||
        entry.date.month != date.month ||
        entry.date.day != date.day) {
      return false;
    }
    if ((entry.amount * 100).round() != (amount * 100).round()) return false;
    final other = _normal(entry.merchant ?? entry.description);
    // Without a reliable merchant, date + amount still deserves a warning, not a block.
    if (name.isEmpty || other.isEmpty || other == 'receiptexpense') return true;
    return name == other ||
        (name.length >= 3 &&
            other.length >= 3 &&
            (name.contains(other) || other.contains(name)));
  }).toList();
}
