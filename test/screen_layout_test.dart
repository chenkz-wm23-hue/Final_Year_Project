import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/screens/login_screen.dart';
import 'package:final_year_project/presentation/screens/register_screen.dart';
import 'package:final_year_project/presentation/screens/dashboard_screen.dart';
import 'package:final_year_project/presentation/screens/transaction_list_screen.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/presentation/screens/budget_screen.dart';
import 'package:final_year_project/presentation/screens/profile_screen.dart';
import 'package:final_year_project/presentation/screens/edit_profile_screen.dart';
import 'package:final_year_project/presentation/screens/recommendations_screen.dart';
import 'package:final_year_project/presentation/screens/risk_alerts_screen.dart';
import 'package:final_year_project/presentation/app_shell.dart';
import 'package:final_year_project/presentation/screens/account_setup_screen.dart';

void main() {
  final setup = AccountSetupScreen(
    monthLabel: 'October 2026',
    onComplete: (_, _, _, _) async {},
    onSignOut: () async {},
  );
  final screens = <String, Widget>{
    'account setup': setup,
    'login': const LoginScreen(),
    'register': const RegisterScreen(),
    'dashboard': const Scaffold(body: DashboardScreen()),
    'transactions': const Scaffold(body: TransactionListScreen()),
    'income': const Scaffold(body: TransactionListScreen(income: true)),
    'expense': const Scaffold(body: TransactionListScreen(income: false)),
    'add expense': const TransactionFormScreen(income: false),
    'add income': const TransactionFormScreen(income: true),
    'budget': const Scaffold(body: BudgetScreen()),
    'profile': const Scaffold(body: ProfileScreen()),
    'edit profile': const EditProfileScreen(),
    'recommendations': const Scaffold(body: RecommendationsScreen()),
    'alerts': const Scaffold(body: RiskAlertsScreen()),
  };
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(740, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} at $size scale $scale', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final store = ExpenseStore();
          addTearDown(store.dispose);
          store.save(
            description:
                'A long transaction description for testing narrow screens',
            amount: 1234567.89,
            date: store.month,
            category: 'Entertainment',
            income: false,
          );
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: ExpenseScope(store: store, child: child!),
              ),
              home: entry.value,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Visit off-screen children as well as the initial viewport.
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            final state = tester.state<ScrollableState>(scrollables.first);
            for (int i = 0; i < 12 && state.position.extentAfter > 0; i++) {
              state.position.jumpTo(
                (state.position.pixels + 200).clamp(
                  0,
                  state.position.maxScrollExtent,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
        });
      }
    }
  }

  testWidgets('all shell destinations fit a narrow phone with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final store = ExpenseStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: ExpenseScope(store: store, child: child!),
        ),
        home: const AppShell(),
      ),
    );
    for (final label in [
      'Dashboard',
      'Income',
      'Expense',
      'Budget',
      'Recommendations',
      'Risk Alerts',
      'Profile',
    ]) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      final destination = find.descendant(
        of: find.byType(Drawer),
        matching: find.widgetWithText(ListTile, label),
      );
      await tester.scrollUntilVisible(
        destination,
        150,
        scrollable: find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(destination.hitTestable(), findsOneWidget);
      await tester.tap(destination);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  for (final item in [
    (setup, 'Finish setup'),
    (const TransactionFormScreen(income: false), 'Save Expense'),
    (const TransactionFormScreen(income: true), 'Save Income'),
    (const EditProfileScreen(), 'Save Changes'),
    (const LoginScreen(), 'Login'),
    (const RegisterScreen(), 'Register'),
  ]) {
    testWidgets('${item.$2} is reachable with keyboard open', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final store = ExpenseStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => ExpenseScope(store: store, child: child!),
          home: item.$1,
        ),
      );
      final button = find.widgetWithText(FilledButton, item.$2);
      await tester.scrollUntilVisible(
        button,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    });
  }
}
