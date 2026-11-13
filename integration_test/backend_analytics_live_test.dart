import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/main.dart' as app;
import 'package:final_year_project/business_logic/backend_analytics_service.dart';
import 'package:final_year_project/presentation/app_shell.dart';
import 'package:final_year_project/presentation/screens/dashboard_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/widgets/backend_analytics_panel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('signed-in backend analytics match saved data and refresh safely', (
    tester,
  ) async {
    await app.main();
    for (var i = 0; i < 120 && find.byType(AppShell).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(
      find.byType(AppShell),
      findsOneWidget,
      reason: 'Requires existing signed-in emulator session',
    );
    final store = ExpenseScope.of(tester.element(find.byType(DashboardScreen)));
    final service = BackendAnalyticsService(client: Supabase.instance.client);
    final analytics = await service.getMyAnalytics();
    final prediction = await service.getMyPredictiveAnalytics();
    expect(analytics['current_month_spending'], closeTo(store.expense, 0.01));
    debugPrint(
      'LIVE_BACKEND budget=${prediction['budget_limit']} savedBudget=${store.repository.budgetFor(store.month)?.amount}',
    );
    debugPrint(
      'LIVE_BASELINE income=${store.income} expense=${store.expense} budget=${store.budget}',
    );
    await tester.scrollUntilVisible(
      find.byType(BackendAnalyticsPanel),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('Financial Summary (all time)').evaluate().isNotEmpty &&
          find.text('Monthly Expenditure Prediction').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Financial Summary (all time)'), findsOneWidget);
    expect(find.text('Monthly Expenditure Prediction'), findsOneWidget);
    expect(find.text('Unable to retrieve analytics.'), findsNothing);
    expect(find.text('Unable to retrieve predictive analytics.'), findsNothing);
    expect(tester.takeException(), isNull);
    await Scrollable.ensureVisible(
      tester.element(find.text('Refresh Analytics')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh Analytics'));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('Financial Summary (all time)').evaluate().isNotEmpty &&
          find.text('Monthly Expenditure Prediction').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Financial Summary (all time)'), findsOneWidget);
    expect(find.text('Monthly Expenditure Prediction'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Monthly Budget Analysis'), findsOneWidget);
    expect(find.textContaining('No monthly budget is available'), findsNothing);
    expect(find.text('RM ${store.budget.toStringAsFixed(2)}'), findsWidgets);
    store.changeMonth(-1);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(BackendAnalyticsPanel),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.textContaining('Online analytics describe the current month'),
      findsOneWidget,
    );
    store.changeMonth(1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    debugPrint('LIVE_ANALYTICS_UI_PASS');
  });
}
