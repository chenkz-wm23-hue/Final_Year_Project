# Smart Expense Tracker architecture

The folders map to the three layers in the system diagram. The application still runs with in-memory data; restarting it resets changes.

```text
lib/
  main.dart                         Entry point
  app.dart                          App setup and dependency ownership
  presentation/
    app_shell.dart                  Navigation
    screens/
      login_screen.dart
      dashboard_screen.dart
      income_screen.dart
      expense_screen.dart
      budget_screen.dart
      profile_screen.dart
      recommendations_screen.dart
      risk_alerts_screen.dart
      ...                           Supporting forms and registration
    state/expense_store.dart        UI state; delegates to business services
    widgets/                        Reusable UI components
    theme/                          Colors
  business_logic/
    authentication.dart             Future authentication contract
    transaction_management.dart     Add, edit, delete and monthly selection
    budget_management.dart          Validate and update monthly budgets
    async_task_producer.dart         Local asynchronous task scheduling utility
    dashboard_calculation.dart      Income, expense, balance and category totals
    rule_based_recommendation.dart  Spending suggestions
    expense_categorisation.dart     Keyword matching
    ml_risk_evaluator.dart           Future ML evaluator contract
    rule_based_risk_evaluator.dart  Current rules-based risk implementation
    profile_management.dart         Profile updates
  data/
    models/
      transaction.dart
      user.dart
      keyword.dart
      budget.dart
      risk_alert.dart
      category.dart
      recommendation.dart
    repositories/
      expense_repository.dart       Storage contract
      in_memory_expense_repository.dart
    database/mysql_database.dart    Future database boundary only
```

## Dependency flow

Screens call the presentation state, which calls business services. Those services use data models and the repository contract. Business and data layers have no Flutter imports. The in-memory repository owns transactions, monthly budgets, the profile, categories and keywords. Recommendation and risk models represent derived results, recalculated when screens read current state.

## Implemented and reserved components

Transaction management, budgeting, dashboard calculations, keyword categorisation, recommendations, profile updates and rule-based alerts are connected to the running UI.

Authentication remains a demo flow. Its file defines a future contract; credentials are not verified. The ML risk evaluator is also a contract, not a trained model. The current alert screen uses the separate rule-based evaluator. The async task producer is an available local scheduling utility, not a background worker or durable queue, and is not required by the synchronous demo.

MySQL is not connected. No database driver, credentials, network calls or persistence have been added. A future server should own MySQL access and expose an authenticated API to the app rather than embedding database credentials in Flutter.

## Verification

Run `flutter analyze` and `flutter test`. Tests cover transaction validation and CRUD, monthly budget isolation, keyword suggestions, and the expense form save/delete flow.
