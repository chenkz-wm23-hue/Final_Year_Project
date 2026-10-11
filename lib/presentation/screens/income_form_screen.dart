import 'package:flutter/material.dart';

import 'transaction_form_screen.dart';

class IncomeFormScreen extends StatelessWidget {
  const IncomeFormScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const TransactionFormScreen(income: true);
}
