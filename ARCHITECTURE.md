# Smart Expense Tracker architecture

The folders map to the three layers in the system diagram. The running app uses Supabase Auth and persistent, per-user database records. The in-memory repository is retained for offline UI tests only.

```text
lib/
  main.dart                         Entry point
  app.dart                          App setup and dependency ownership
  connected_app.dart                Auth-driven navigation and account loading
  config/supabase_config.dart        Public project URL and publishable key
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
    authentication.dart             Authentication contract
    supabase_authentication.dart     Email/password Auth implementation
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
      supabase_expense_repository.dart Async, account-scoped persistence
    database/supabase_database.dart Client initialization and session restoration
```

## Dependency flow

Screens call the presentation state, which calls business services and the repository contract. The Supabase adapter maps database records to domain models and updates its local cache only after successful writes. Auth changes dispose account state and reset navigation. Recommendation and risk models remain derived results, recalculated from the loaded transactions and budgets; this client does not write backend-generated insight tables.

## Implemented and reserved components

Transaction management, budgeting, dashboard calculations, keyword categorisation, recommendations, profile updates and rule-based alerts are connected to the running UI.

Authentication uses Supabase email/password sign-in, registration and logout. When confirmation is required, registration asks the user to confirm their email before logging in. The ML risk evaluator remains a contract, not a trained model. The current alert screen uses the separate rule-based evaluator. The async task producer is a local scheduling utility, not a durable background worker.

The Supabase database is deployed to project `plmmhvvxsqiudqqrfijl`. See `supabase/README.md` for access policies and configuration. Only a public publishable key is embedded; Auth sessions and row-level security enforce access. Saving requires a network connection; errors keep forms open and do not apply unconfirmed changes to the cache.

## Verification

Run `flutter analyze` and `flutter test`. Tests cover responsive layouts, validation, the expense form flow, and mock-HTTP Supabase Auth/CRUD contracts including failed writes and reloading records. Mock tests do not replace a real email-confirmation and two-account RLS smoke test.
