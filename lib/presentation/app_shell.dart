import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/income_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/risk_alerts_screen.dart';
import 'screens/add_expense_screen.dart';
import 'theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  static const labels = [
    'Dashboard',
    'Income',
    'Expense',
    'Budget',
    'Recommendations',
    'Risk Alerts',
    'Profile',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.south_west,
    Icons.north_east,
    Icons.account_balance_wallet_outlined,
    Icons.lightbulb_outline,
    Icons.shield_outlined,
    Icons.person_outline,
  ];
  static const pages = [
    DashboardScreen(),
    IncomeScreen(),
    ExpenseScreen(),
    BudgetScreen(),
    RecommendationsScreen(),
    RiskAlertsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(labels[selected]),
      backgroundColor: appCanvas,
      actions: [
        IconButton(
          tooltip: 'Risk alerts',
          onPressed: () => setState(() => selected = 5),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    ),
    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Smart Expense\nTracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: appIndigo,
                ),
              ),
            ),
            for (int i = 0; i < labels.length; i++)
              ListTile(
                selected: selected == i,
                selectedColor: appIndigo,
                leading: Icon(icons[i]),
                title: Text(labels[i]),
                onTap: () {
                  setState(() => selected = i);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    ),
    body: SafeArea(child: pages[selected]),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Add expense',
      backgroundColor: appIndigo,
      foregroundColor: Colors.white,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
      ),
      child: const Icon(Icons.add),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: [0, 2, 3, 6].contains(selected)
          ? [0, 2, 3, 6].indexOf(selected)
          : 0,
      onDestinationSelected: (i) => setState(() => selected = [0, 2, 3, 6][i]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Expense',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Budget',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  );
}
