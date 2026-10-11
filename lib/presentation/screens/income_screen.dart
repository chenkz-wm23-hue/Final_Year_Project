import 'package:flutter/material.dart';

import 'transaction_list_screen.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const TransactionListScreen(income: true);
}
