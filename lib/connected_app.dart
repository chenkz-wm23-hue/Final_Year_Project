import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'business_logic/supabase_authentication.dart';
import 'business_logic/account_setup.dart';
import 'presentation/screens/account_setup_screen.dart';
import 'data/repositories/supabase_expense_repository.dart';
import 'presentation/state/auth_scope.dart';
import 'presentation/state/expense_store.dart';
import 'presentation/app_shell.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/widgets/async_button.dart';

class ConnectedApp extends StatefulWidget {
  const ConnectedApp({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<ConnectedApp> createState() => _ConnectedAppState();
}

class _ConnectedAppState extends State<ConnectedApp> {
  late final SupabaseAuthentication auth;
  late final StreamSubscription<AuthState> subscription;
  String? userId;
  ExpenseStore? store;
  Future<void>? loading;
  final messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    auth = SupabaseAuthentication(widget.client);
    _setUser(widget.client.auth.currentUser?.id);
    subscription = widget.client.auth.onAuthStateChange.listen(
      (event) {
        if (!mounted) return;
        final id = event.session?.user.id;
        if (id != null && auth.registrationRequiresLogin) return;
        if (id != userId) setState(() => _setUser(id));
      },
      onError: (Object error) {
        messenger.currentState?.showSnackBar(
          SnackBar(content: Text(friendlyError(error))),
        );
      },
    );
  }

  void _setUser(String? id) {
    store?.dispose();
    store = null;
    userId = id;
    if (id == null) {
      loading = null;
      return;
    }
    final repository = SupabaseExpenseRepository(widget.client, id);
    store = ExpenseStore(repository: repository);
    loading = repository.load();
  }

  @override
  void dispose() {
    subscription.cancel();
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    // Recreate the navigator on account changes, removing old forms and cached screens.
    key: ValueKey(userId),
    scaffoldMessengerKey: messenger,
    debugShowCheckedModeBanner: false,
    title: 'Smart Expense Tracker',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appCanvas,
      colorScheme: ColorScheme.fromSeed(seedColor: appIndigo),
    ),
    builder: (context, child) => AuthScope(
      auth: auth,
      child: store == null
          ? child!
          : ExpenseScope(store: store!, child: child!),
    ),
    home: userId == null
        ? const SplashScreen()
        : FutureBuilder<void>(
            future: loading,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your account…'),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Your account data could not be loaded. Check your connection and retry.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() => _setUser(userId)),
                              child: const Text('Retry'),
                            ),
                            AsyncButton(
                              label: 'Sign out',
                              onPressed: auth.signOut,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              if (AccountSetup(widget.client).required) {
                final activeStore = store!;
                final setupMonth = activeStore.month;
                return AccountSetupScreen(
                  monthLabel: activeStore.monthLabel,
                  onSignOut: auth.signOut,
                  onComplete:
                      (income, budget, savingGoalName, savingGoalAmount) async {
                    await AccountSetup(widget.client).complete(
                      activeStore.repository,
                      setupMonth,
                      income,
                      budget,
                      savingGoalName: savingGoalName,
                      savingGoalAmount: savingGoalAmount,
                    );
                    if (mounted && identical(store, activeStore)) {
                      setState(() {});
                    }
                  },
                );
              }
              return const AppShell();
            },
          ),
  );
}
