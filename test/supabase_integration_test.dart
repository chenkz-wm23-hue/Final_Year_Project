import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/business_logic/supabase_authentication.dart';
import 'package:final_year_project/data/repositories/supabase_expense_repository.dart';
import 'package:final_year_project/data/models/budget.dart';
import 'package:final_year_project/data/models/user.dart';
import 'package:final_year_project/connected_app.dart';
import 'package:final_year_project/presentation/app_shell.dart';
import 'package:final_year_project/presentation/screens/auth_form_screen.dart';
import 'package:final_year_project/presentation/state/auth_scope.dart';
import 'package:final_year_project/business_logic/account_setup.dart';
import 'package:final_year_project/presentation/screens/account_setup_screen.dart';
import 'package:final_year_project/presentation/screens/recommendations_screen.dart';
import 'package:final_year_project/presentation/screens/risk_alerts_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';

class MemoryAuthStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

// Contract tests against a mock HTTP server; no real accounts or emails created.
void main() {
  const uid = '11111111-1111-4111-8111-111111111111';
  late SupabaseClient client;
  late SupabaseAuthentication auth;
  late List<http.Request> requests;
  late Map<int, Map<String, dynamic>> rows;
  late Map<String, dynamic> profile;
  late List<Map<String, dynamic>> budgets;
  bool rejectWrites = false;
  bool rejectLogin = false;
  String loginFailureCode = 'invalid_credentials';
  bool autoConfirm = false;
  bool rejectMetadata = false;
  bool rejectInsights = false;
  List<Map<String, dynamic>> savedRecommendations = [];
  List<Map<String, dynamic>> savedAlerts = [];
  final user = {
    'id': uid,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'student@example.com',
    'created_at': '2026-01-01T00:00:00Z',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  };
  http.Response response(Object value, [int status = 200]) => http.Response(
    jsonEncode(value),
    status,
    headers: {
      'content-type': 'application/json',
      'x-supabase-api-version': '2024-01-01',
    },
    request: requests.last,
  );
  setUp(() {
    requests = [];
    rows = {};
    budgets = [];
    profile = {'id': uid, 'full_name': 'Student', 'phone': '', 'address': ''};
    rejectWrites = false;
    rejectLogin = false;
    loginFailureCode = 'invalid_credentials';
    autoConfirm = false;
    rejectMetadata = false;
    rejectInsights = false;
    savedRecommendations = [];
    savedAlerts = [];
    user['user_metadata'] = <String, dynamic>{};
    client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: MemoryAuthStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/signup')) {
          user['user_metadata'] = jsonDecode(request.body)['data'];
          if (!autoConfirm) return response(user);
        }
        if (path.endsWith('/user')) {
          if (rejectMetadata) {
            return response({'msg': 'Unable to save setup'}, 400);
          }
          user['user_metadata'] = {
            ...user['user_metadata'] as Map<String, dynamic>,
            ...jsonDecode(request.body)['data'],
          };
          return response(user);
        }
        if (path.endsWith('/token') || path.endsWith('/signup')) {
          if (rejectLogin) {
            return response({
              'code': loginFailureCode,
              'msg': 'Invalid login credentials',
            }, 400);
          }
          final payload = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': uid,
                    'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                  }),
                ),
              )
              .replaceAll('=', '');
          return response({
            'access_token': 'e30.$payload.signature',
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': user,
          });
        }
        if (path.endsWith('/logout')) return http.Response('', 204);
        final table = path.split('/').last;
        if (request.method == 'GET') {
          if (['recommendations', 'risk_alerts'].contains(table) &&
              rejectInsights) {
            return response({'message': 'Unavailable'}, 503);
          }
          return response(switch (table) {
            'recommendations' => savedRecommendations,
            'risk_alerts' => savedAlerts,
            'categories' => [
              {'id': 1, 'name': 'Food', 'transaction_type': 'expense'},
            ],
            'keywords' => [
              {'id': 1, 'keyword': 'lunch', 'category_id': 1},
            ],
            'profiles' => profile,
            'transactions' => rows.values.toList(),
            'budgets' => budgets,
            _ => throw StateError('Unexpected request: $path'),
          });
        }
        if (rejectWrites) {
          return response({'message': 'Denied', 'code': '42501'}, 403);
        }
        final body = request.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(request.body) as Map<String, dynamic>;
        if (table == 'transactions') {
          if (request.method == 'POST') {
            rows[42] = {'id': 42, ...body};
            return response(rows[42]!);
          }
          expect(request.url.queryParameters['user_id'], 'eq.$uid');
          expect(request.url.queryParameters['id'], 'eq.42');
          if (request.method == 'DELETE') return response(rows.remove(42)!);
          rows[42] = {...rows[42]!, ...body};
          return response(rows[42]!);
        }
        if (table == 'budgets') {
          expect(request.url.queryParameters['on_conflict'], 'user_id,month');
          budgets = [
            {'id': 1, ...body},
          ];
          return response(budgets.single);
        }
        if (table == 'profiles') {
          expect(body.containsKey('email'), isFalse);
          expect(request.url.queryParameters['id'], 'eq.$uid');
          profile = {...profile, ...body};
          return response(profile);
        }
        throw StateError('Unexpected request: $path');
      }),
    );
    auth = SupabaseAuthentication(client);
  });
  tearDown(() async => client.dispose());

  testWidgets(
    'insight screens display persisted results and retry read failures',
    (tester) async {
      await tester.runAsync(
        () => auth.signIn('student@example.com', 'password123'),
      );
      final month = DateTime.now();
      final date = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      savedRecommendations = [
        {
          'id': 1,
          'month': date,
          'title': 'Persisted recommendation',
          'description': 'From Supabase',
          'label': 'Budget',
        },
      ];
      savedAlerts = [
        {
          'id': 2,
          'month': date,
          'title': 'Persisted risk alert',
          'description': 'From Supabase',
          'label': 'Budget',
          'severity': 'high',
        },
      ];
      final repo = SupabaseExpenseRepository(client, uid);
      await tester.runAsync(repo.load);
      final store = ExpenseStore(repository: repo);
      Future<void> screen(Widget child) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ExpenseScope(
              store: store,
              child: Scaffold(body: child),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await screen(const RecommendationsScreen());
      expect(find.text('Persisted recommendation'), findsOneWidget);
      await screen(const RiskAlertsScreen());
      expect(find.text('Persisted risk alert'), findsOneWidget);
      rejectInsights = true;
      await tester.runAsync(store.refreshInsights);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Saved insights could not be loaded'),
        findsOneWidget,
      );
      expect(find.text('No spending alerts'), findsNothing);
      expect(find.text('No activity this month'), findsNothing);
      rejectInsights = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Persisted risk alert'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  test('persisted insights reload by month and failed reads do not fail committed writes', () async {
    await auth.signIn('student@example.com', 'password123');
    savedRecommendations = [
      {
        'id': 1,
        'month': '2026-10-01',
        'title': 'Server recommendation',
        'description': 'Saved result',
        'label': 'Budget',
      },
    ];
    savedAlerts = [
      {
        'id': 2,
        'month': '2026-10-01',
        'title': 'Server alert',
        'description': 'Saved alert',
        'label': 'Budget',
        'severity': 'high',
      },
    ];
    final repo = SupabaseExpenseRepository(client, uid);
    await repo.load();
    expect(
      repo.recommendationsFor(DateTime(2026, 10)).single.title,
      'Server recommendation',
    );
    expect(repo.riskAlertsFor(DateTime(2026, 10)).single.severity.name, 'high');
    expect(repo.recommendationsFor(DateTime(2026, 11)), isEmpty);
    rejectInsights = true;
    await repo.saveBudget(
      const MonthlyBudget(year: 2026, month: 10, amount: 900),
    );
    expect(repo.budgetFor(DateTime(2026, 10))!.amount, 900);
    expect(repo.insightsUnavailable, isTrue);
    expect(repo.riskAlertsFor(DateTime(2026, 10)), isEmpty);
    rejectInsights = false;
    await repo.refreshInsights();
    expect(repo.insightsUnavailable, isFalse);
    expect(repo.riskAlertsFor(DateTime(2026, 10)), hasLength(1));
    for (final request in requests.where(
      (r) =>
          r.url.path.endsWith('/recommendations') ||
          r.url.path.endsWith('/risk_alerts'),
    )) {
      expect(request.url.queryParameters['user_id'], 'eq.$uid');
    }
  });

  Future<void> openForm(WidgetTester tester, {bool register = false}) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => AuthScope(auth: auth, child: child!),
        home: AuthFormScreen(register: register),
      ),
    );
  }

  testWidgets(
    'registration rejects empty fields, invalid email, short and mismatched passwords',
    (tester) async {
      await openForm(tester, register: true);
      await tester.tap(find.text('Register', skipOffstage: false).last);
      await tester.pumpAndSettle();
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test Student');
      await tester.enterText(fields.at(1), 'not-an-email');
      await tester.enterText(fields.at(2), 'short');
      await tester.enterText(fields.at(3), 'different');
      await tester.tap(find.text('Register').last);
      await tester.pumpAndSettle();
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(requests, isEmpty);
    },
  );

  testWidgets(
    'registration form submits and shows confirmation notice without signing in',
    (tester) async {
      await openForm(tester, register: true);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test Student');
      await tester.enterText(fields.at(1), 'student@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.text('Register').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Check your email to confirm'),
        findsOneWidget,
      );
      expect(client.auth.currentSession, isNull);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(
        requests.where((r) => r.url.path.endsWith('/signup')),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid credentials mark email field and clear on editing before retry',
    (tester) async {
      rejectLogin = true;
      await openForm(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'wrong-password',
      );
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Invalid email or password.'), findsOneWidget);
      expect(
        tester
            .state<FormFieldState<String>>(find.byType(TextFormField).first)
            .hasError,
        isTrue,
      );
      expect(client.auth.currentSession, isNull);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byType(TextFormField).first,
        'newuser@gmail.com',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Invalid email or password.'), findsNothing);
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Invalid email or password.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'correct-password',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .state<FormFieldState<String>>(find.byType(TextFormField).first)
            .hasError,
        isFalse,
      );
      rejectLogin = false;
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();
      expect(client.auth.currentSession, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('other auth failures do not mark the email as invalid', (
    tester,
  ) async {
    rejectLogin = true;
    loginFailureCode = 'email_not_confirmed';
    await openForm(tester);
    await tester.enterText(
      find.byType(TextFormField).first,
      'student@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<FormFieldState<String>>(find.byType(TextFormField).first)
          .hasError,
      isFalse,
    );
    expect(find.textContaining('Invalid email or password.'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('auth events replace protected navigation on login and logout', (
    tester,
  ) async {
    await tester.pumpWidget(ConnectedApp(client: client));
    expect(find.text('Get started'), findsOneWidget);
    await tester.runAsync(
      () => auth.signIn('student@example.com', 'password123'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(auth.signOut);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'registration sends metadata and waits for email confirmation',
    () async {
      await auth.register(' Student ', ' student@example.com ', 'password123');
      final body = jsonDecode(requests.single.body);
      expect(body['email'], 'student@example.com');
      expect(body['data']['full_name'], 'Student');
      expect(client.auth.currentSession, isNull);
    },
  );
  testWidgets('saving goal closes safely and can be reopened and cancelled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await auth.signIn('student@example.com', 'password123');
    await tester.pumpWidget(ConnectedApp(client: client));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budget').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set saving goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Laptop');
    await tester.enterText(find.byType(TextFormField).at(1), '3000');
    await tester.enterText(find.byType(TextFormField).at(2), '500');
    rejectMetadata = true;
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Unable to save setup'), findsOneWidget);
    expect(tester.takeException(), isNull);
    rejectMetadata = false;
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Laptop'), findsOneWidget);
    expect(client.auth.currentUser!.userMetadata!['saving_goal_amount'], 3000);
    await tester.tap(find.text('Update saving goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Unsaved');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Laptop'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'auto-confirm signup returns to Login, then setup, then dashboard',
    (tester) async {
      autoConfirm = true;
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ConnectedApp(client: client));
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Don’t have an account? Register'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Student');
      await tester.enterText(fields.at(1), 'student@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(client.auth.currentSession, isNull);
      expect(find.byType(AppShell), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountSetupScreen), findsOneWidget);
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      expect(budgets, isEmpty);
      await tester.enterText(find.byType(TextFormField).at(0), '2000');
      await tester.enterText(find.byType(TextFormField).at(1), '800');
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(budgets.single['amount'], 800);
      expect(
        client.auth.currentUser!.userMetadata!['expected_monthly_income'],
        2000,
      );
      expect(
        rows,
        isEmpty,
      ); // Expected income is not fabricated received money.
      await tester.runAsync(auth.signOut);
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => auth.signIn('student@example.com', 'password123'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountSetupScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('setup remains incomplete after failure and retry does not duplicate budget', () async {
    user['user_metadata'] = {'onboarding_required': true};
    await auth.signIn('student@example.com', 'password123');
    final repo = SupabaseExpenseRepository(client, uid);
    await repo.load();
    final setup = AccountSetup(client);
    rejectMetadata = true;
    await expectLater(
      setup.complete(repo, DateTime(2026, 10), '0', '700'),
      throwsA(isA<AuthException>()),
    );
    expect(setup.required, isTrue);
    expect(budgets, hasLength(1));
    rejectMetadata = false;
    await setup.complete(repo, DateTime(2026, 10), '0', '700');
    expect(setup.required, isFalse);
    expect(budgets, hasLength(1));
  });

  test('setup validates monetary precision and limits', () {
    for (final value in [
      '',
      '-1',
      'NaN',
      'Infinity',
      '0.001',
      '10000000000',
      'abc',
    ]) {
      expect(AccountSetup.validateMoney(value, allowZero: true), isNotNull);
    }
    expect(AccountSetup.validateMoney('0', allowZero: true), isNull);
    expect(AccountSetup.validateMoney('0'), isNotNull);
    expect(AccountSetup.validateMoney('9999999999.99'), isNull);
  });
  test(
    'login, CRUD, budget and profile reload from server; logout blocks writes',
    () async {
      await auth.signIn(' student@example.com ', 'password123');
      expect(client.auth.currentUser?.id, uid);
      final repository = SupabaseExpenseRepository(client, uid);
      await repository.load();
      expect(repository.transactions, isEmpty);
      TransactionEntry entry(int id, double amount) => TransactionEntry(
        id: id,
        description: 'Lunch',
        category: 'Food',
        amount: amount,
        date: DateTime(2026, 10, 20),
        income: false,
      );
      await repository.upsertTransaction(entry(0, 12));
      expect(repository.transactions.single.id, 42);
      expect(rows[42]!['user_id'], uid);
      expect(rows[42]!['transaction_date'], '2026-10-20');
      await repository.upsertTransaction(entry(42, 18));
      expect(repository.transactions.single.amount, 18);
      await repository.saveBudget(
        const MonthlyBudget(year: 2026, month: 10, amount: 900),
      );
      await repository.saveUser(
        const UserProfile(
          name: 'Updated',
          email: 'ignored@example.com',
          phone: '123',
          address: 'Home',
        ),
      );
      final reloaded = SupabaseExpenseRepository(client, uid);
      await reloaded.load();
      expect(reloaded.transactions.single.amount, 18);
      expect(reloaded.budgetFor(DateTime(2026, 10))!.amount, 900);
      expect(reloaded.user.name, 'Updated');
      expect(reloaded.user.email, 'student@example.com');
      rejectWrites = true;
      await expectLater(
        reloaded.upsertTransaction(entry(42, 99)),
        throwsA(isA<PostgrestException>()),
      );
      expect(reloaded.transactions.single.amount, 18);
      await expectLater(
        reloaded.deleteTransaction(42),
        throwsA(isA<PostgrestException>()),
      );
      expect(reloaded.transactions, hasLength(1));
      rejectWrites = false;
      await reloaded.deleteTransaction(42);
      expect(reloaded.transactions, isEmpty);
      await auth.signOut();
      await expectLater(
        reloaded.upsertTransaction(entry(0, 10)),
        throwsStateError,
      );
    },
  );
}
