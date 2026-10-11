import 'package:flutter/material.dart';

import 'transaction_form_screen.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const TransactionFormScreen(income: false);
}
