import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_year_project/app.dart';

void main() {
  testWidgets('shows the Smart Expense Tracker splash screen', (tester) async {
    await tester.pumpWidget(const SmartExpenseApp());

    expect(find.text('Smart\nExpense Tracker'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('splash gradient fills the phone viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const SmartExpenseApp());

    final background = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).gradient != null,
    );
    expect(tester.getRect(background), const Rect.fromLTWH(0, 0, 390, 844));
    expect(tester.getCenter(find.text('Get started')).dx, 195);
    expect(tester.takeException(), isNull);
  });
}
