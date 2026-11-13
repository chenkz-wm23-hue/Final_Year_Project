import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/business_logic/backend_analytics_service.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/widgets/backend_analytics_panel.dart';

void main() {
  late SupabaseClient client;
  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((_) async {
        final payload = base64Url
            .encode(
              utf8.encode(
                jsonEncode({
                  'sub': 'user-test',
                  'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                }),
              ),
            )
            .replaceAll('=', '');
        return http.Response(
          jsonEncode({
            'access_token': 'e30.$payload.signature',
            'refresh_token': 'fake-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': 'user-test',
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDown(() async => client.dispose());
  Future<void> login() async {
    await client.auth.signInWithPassword(
      email: 'test@example.com',
      password: 'test-password',
    );
  }

  test('signed-out analytics fail before any backend request', () async {
    final service = BackendAnalyticsService(
      client: client,
      httpClient: MockClient((_) async {
        fail('Must not send signed-out requests');
      }),
    );
    await expectLater(
      service.getMyAnalytics(),
      throwsA(isA<AnalyticsException>()),
    );
  });

  test('both endpoints attach current session and parse objects', () async {
    await login();
    final paths = <String>[];
    final service = BackendAnalyticsService(
      client: client,
      httpClient: MockClient((r) async {
        paths.add(r.url.path);
        expect(
          r.headers['Authorization'],
          'Bearer ${client.auth.currentSession!.accessToken}',
        );
        return http.Response(
          '{"financial_summary":{"total_expenses":25}}',
          200,
        );
      }),
    );
    expect((await service.getMyAnalytics())['financial_summary'], {
      'total_expenses': 25,
    });
    await service.getMyPredictiveAnalytics();
    expect(paths, ['/api/v1/my-analytics', '/api/v1/my-predictive-analytics']);
  });

  test(
    'handles auth errors, server errors and malformed responses safely',
    () async {
      await login();
      for (final sample in [
        (401, 'secret'),
        (503, 'private traceback'),
        (200, '<html>'),
        (200, '[]'),
        (200, '{}'),
      ]) {
        final service = BackendAnalyticsService(
          client: client,
          httpClient: MockClient(
            (_) async => http.Response(sample.$2, sample.$1),
          ),
        );
        await expectLater(
          service.getMyAnalytics(),
          throwsA(
            isA<AnalyticsException>().having(
              (e) => e.message,
              'safe error',
              isNot(contains(sample.$2)),
            ),
          ),
        );
      }
    },
  );

  test('slow server times out with retry guidance', () async {
    await login();
    final service = BackendAnalyticsService(
      client: client,
      timeout: const Duration(milliseconds: 5),
      httpClient: MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      service.getMyAnalytics(),
      throwsA(
        isA<AnalyticsException>().having(
          (e) => e.message,
          'timeout',
          contains('retry'),
        ),
      ),
    );
  });

  testWidgets(
    'analytics refresh after saves without late-final crash and hide for historical month',
    (tester) async {
      await login();
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = ExpenseStore();
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      store.month = DateTime(now.year, now.month);
      var calls = 0;
      final service = BackendAnalyticsService(
        client: client,
        httpClient: MockClient((_) async {
          calls++;
          return http.Response(
            '{"budget_analysis":{"budget_limit":999,"actual_spending":9999},"financial_summary":{},"expenditure_prediction":{"prediction_status":"insufficient_data"},"budget_risk_assessment":{"risk_level":"low"}}',
            200,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseScope(
            store: store,
            child: Scaffold(
              body: SingleChildScrollView(
                child: BackendAnalyticsPanel(service: service),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text("RM 999.00"), findsNothing);
      expect(find.textContaining('Budget not set'), findsOneWidget);
      expect(find.text('RM 1500.00'), findsNothing);
      await store.setBudget(1600);
      await tester.pumpAndSettle();
      expect(calls, 4);
      expect(find.text('RM 1600.00'), findsWidgets);
      expect(find.textContaining('Saved budget'), findsOneWidget);
      await store.save(
        description: 'Test expense',
        amount: 1700,
        date: store.month,
        category: 'Food',
        income: false,
      );
      await tester.pumpAndSettle();
      expect(find.text(money(store.remaining)), findsOneWidget);
      expect(find.text('Status: exceeded'), findsOneWidget);
      expect(tester.takeException(), isNull);
      store.changeMonth(-1);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Online analytics describe the current month'),
        findsOneWidget,
      );
      expect(calls, 6);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
