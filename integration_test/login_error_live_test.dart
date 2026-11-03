import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/config/supabase_config.dart';
import 'package:final_year_project/connected_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Unregistered Gmail shows red inline error and clears on editing', (
    tester,
  ) async {
    // A separate client uses real Auth without changing the user's saved session.
    final client = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.publishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    try {
      await tester.pumpWidget(ConnectedApp(client: client));
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      const email = String.fromEnvironment('TEST_EMAIL');
      expect(email.endsWith('@gmail.com'), isTrue);
      await tester.enterText(find.byType(TextFormField).first, email);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Unregistered-test-only-739!',
      );
      await tester.ensureVisible(find.text('Login').last);
      await tester.tap(find.text('Login').last);
      const message =
          'Invalid email or password. Check your details or register a new account.';
      for (var i = 0; i < 60 && find.text(message).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      final field = find.byType(TextFormField).first;
      expect(tester.state<FormFieldState<String>>(field).hasError, isTrue);
      final errorElement = tester.element(find.text(message));
      final errorText = tester.widget<Text>(find.text(message));
      final renderedColor =
          errorText.style?.color ??
          DefaultTextStyle.of(errorElement).style.color;
      expect(renderedColor, Theme.of(errorElement).colorScheme.error);
      expect(client.auth.currentSession, isNull);
      expect(tester.takeException(), isNull);
      await tester.enterText(field, 'edited.address@gmail.com');
      await tester.pumpAndSettle();
      expect(find.text(message), findsNothing);
      expect(tester.state<FormFieldState<String>>(field).hasError, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await client.dispose();
    }
  });
}
