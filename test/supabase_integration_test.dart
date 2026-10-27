import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/business_logic/supabase_authentication.dart';
import 'package:final_year_project/data/repositories/supabase_expense_repository.dart';
import 'package:final_year_project/data/models/transaction.dart';
import 'package:final_year_project/data/models/budget.dart';
import 'package:final_year_project/data/models/user.dart';
import 'package:final_year_project/connected_app.dart';
import 'package:final_year_project/presentation/app_shell.dart';

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
    headers: {'content-type': 'application/json'},
    request: requests.last,
  );
  setUp(() {
    requests = [];
    rows = {};
    budgets = [];
    profile = {'id': uid, 'full_name': 'Student', 'phone': '', 'address': ''};
    rejectWrites = false;
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
        if (path.endsWith('/token')) {
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
        if (path.endsWith('/signup')) return response(user);
        if (path.endsWith('/logout')) return http.Response('', 204);
        final table = path.split('/').last;
        if (request.method == 'GET') {
          return response(switch (table) {
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
