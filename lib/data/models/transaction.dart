class TransactionEntry {
  final int id;
  final String description, category;
  final double amount;
  final DateTime date;
  final bool income;
  final String? receiptPath, merchant;
  const TransactionEntry({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    required this.income,
    this.receiptPath,
    this.merchant,
  });
}
