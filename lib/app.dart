import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connected_app.dart';

import 'presentation/theme/app_colors.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/state/expense_store.dart';

class SmartExpenseApp extends StatefulWidget {
  const SmartExpenseApp({super.key, this.client});
  final SupabaseClient? client;
  @override
  State<SmartExpenseApp> createState() => _SmartExpenseAppState();
}

class _SmartExpenseAppState extends State<SmartExpenseApp> {
  final store = ExpenseStore();
  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.client != null
      ? ConnectedApp(client: widget.client!)
      : MaterialApp(
          title: 'Smart Expense Tracker',
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              ExpenseScope(store: store, child: child!),
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: appCanvas,
            colorScheme: ColorScheme.fromSeed(seedColor: appIndigo),
            fontFamily: 'Arial',
          ),
          home: const SplashScreen(),
        );
}
