import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:final_year_project/main.dart' as app;
import 'package:final_year_project/presentation/screens/auth_form_screen.dart';
import 'package:final_year_project/presentation/screens/transaction_form_screen.dart';
import 'package:final_year_project/presentation/screens/budget_screen.dart';
import 'package:final_year_project/presentation/screens/edit_profile_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/screens/account_setup_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android first-time setup validates and submits planning values',
    (tester) async {
      String? savedIncome, savedBudget;
      await tester.pumpWidget(
        MaterialApp(
          home: AccountSetupScreen(
            monthLabel: 'October 2026',
            onSignOut: () async {},
            onComplete: (income, budget, savingGoalName, savingGoalAmount) async {
              savedIncome = income;
              savedBudget = budget;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Finish setup'));
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      expect(savedIncome, isNull);
      await tester.enterText(find.byType(TextFormField).at(0), '0');
      await tester.enterText(find.byType(TextFormField).at(1), '650.50');
      await tester.ensureVisible(find.text('Finish setup'));
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      expect(savedIncome, '0');
      expect(savedBudget, '650.50');
      expect(tester.takeException(), isNull);
    },
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('Android real startup and invalid auth forms', (tester) async {
    await app.main();
    for (
      var i = 0;
      i < 40 && find.text('Get started').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    // If a real session is already restored, do not log the user out.
    if (find.text('Get started').evaluate().isNotEmpty) {
      await tapText(tester, 'Get started');
    } else {
      await tester.pumpWidget(const MaterialApp(home: AuthFormScreen()));
      await tester.pumpAndSettle();
    }
    await tapText(tester, 'Login');
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    await tapText(tester, 'Don’t have an account? Register');
    await tapText(tester, 'Register');
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Validation Test');
    await tester.enterText(fields.at(1), 'invalid-email');
    await tester.enterText(fields.at(2), 'short');
    await tester.enterText(fields.at(3), 'different');
    await tapText(tester, 'Register');
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final income in [false, true]) {
    testWidgets('Android ${income ? 'income' : 'expense'} invalid amounts', (
      tester,
    ) async {
      final store = ExpenseStore();
      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseScope(
            store: store,
            child: TransactionFormScreen(income: income),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = income ? 'Save Income' : 'Save Expense';
      await tapText(tester, label);
      expect(find.text('Enter a description'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Validation only',
      );
      for (final value in ['0', '-5', 'abc', 'NaN', 'Infinity']) {
        await tester.enterText(find.byType(TextFormField).at(1), value);
        await tapText(tester, label);
        expect(find.text('Enter an amount greater than zero'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }

  testWidgets(
    'Android budget validates and saves; profile rejects empty name',
    (tester) async {
      final store = ExpenseStore();
      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseScope(
            store: store,
            child: const Scaffold(body: BudgetScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Update Budget');
      for (final value in ['0', '-10', 'abc']) {
        await tester.enterText(find.byType(TextFormField), value);
        await tapText(tester, 'Save');
        expect(find.text('Enter a positive budget'), findsOneWidget);
      }
      await tester.enterText(find.byType(TextFormField), '800');
      await tapText(tester, 'Save');
      expect(store.budget, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseScope(store: store, child: const EditProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '   ');
      await tapText(tester, 'Save Changes');
      expect(find.text('Enter your name'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
