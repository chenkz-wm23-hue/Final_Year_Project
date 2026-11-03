import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/main.dart' as app;
import 'package:final_year_project/presentation/app_shell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Live Android saving goal saves, reopens and cancels without crashing',
    (tester) async {
      await app.main();
      for (
        var i = 0;
        i < 120 && find.byType(AppShell).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(
        find.byType(AppShell),
        findsOneWidget,
        reason: 'A signed-in account with setup completed is needed for this live test.',
      );
      final client = Supabase.instance.client;
      final original = Map<String, dynamic>.from(
        client.auth.currentUser!.userMetadata ?? {},
      );
      const goalKeys = [
        'saving_goal_name',
        'saving_goal_amount',
        'monthly_saving_amount',
      ];
      try {
        await tester.tap(find.text('Budget').last);
        await tester.pumpAndSettle();
        final edit = find.text(
          original['saving_goal_name'] == null
              ? 'Set saving goal'
              : 'Update saving goal',
        );
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Goal regression test',
        );
        await tester.enterText(find.byType(TextFormField).at(1), '3000');
        await tester.enterText(find.byType(TextFormField).at(2), '500');
        await tester.ensureVisible(find.text('Save goal'));
        await tester.tap(find.text('Save goal'));
        for (
          var i = 0;
          i < 120 && find.byType(AlertDialog).evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Goal regression test'), findsOneWidget);
        final saved = (await client.auth.getUser()).user!.userMetadata!;
        expect(saved['saving_goal_name'], 'Goal regression test');
        expect(saved['saving_goal_amount'], 3000);
        expect(saved['monthly_saving_amount'], 500);
        await tester.ensureVisible(find.text('Update saving goal'));
        await tester.tap(find.text('Update saving goal'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          'Goal regression test',
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'Unsaved change',
        );
        await tester.ensureVisible(find.text('Cancel'));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Goal regression test'), findsOneWidget);
      } finally {
        await client.auth.updateUser(
          UserAttributes(
            data: {for (final key in goalKeys) key: original[key]},
          ),
        );
      }
    },
  );
}
