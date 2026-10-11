import 'package:flutter_test/flutter_test.dart';

import 'package:final_year_project/app.dart';

void main() {
  testWidgets('shows the Smart Expense Tracker splash screen', (tester) async {
    await tester.pumpWidget(const SmartExpenseApp());

    expect(find.text('Smart\nExpense Tracker'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
