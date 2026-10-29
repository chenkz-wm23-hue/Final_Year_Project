# Supabase database setup

## Current status

Applied to Supabase project `plmmhvvxsqiudqqrfijl` on 12 October 2026. Hosted migration: `20261012154113_create_expense_tracker`. All seven tables have row-level security enabled; 12 categories and 22 keywords are seeded. Supabase's security advisor reported no findings. The full transactional smoke test could not be executed through the connector because it returned `Invalid or expired requestState` twice; do not treat it as passed.

Follow-up read-only verification confirmed the ownership predicates and both update `USING`/`WITH CHECK` rules, anonymous SELECT denial on all seven tables, and the empty monthly summary (zero income/expense and RM 1,500 default budget). Security advisor still reports no findings. These checks do not replace the pending two-user transactional smoke test.

The Flutter app now connects to this project using Supabase Auth and `SupabaseExpenseRepository`. Transactions, monthly budgets and profile edits are saved remotely. Do not reapply the initial migration to this project.

## Apply to a new project

1. Create or select your Supabase development project. Use a new project or inspect existing tables first: this initial migration intentionally refuses to overwrite tables with the same names.
2. Open the project's SQL Editor.
3. Paste the complete contents of `migrations/20261012154113_create_expense_tracker.sql` and run once. It runs inside a transaction so a failure rolls back the schema changes.
4. Confirm all seven tables exist in the Table Editor and RLS is enabled.
5. Create a test account through Supabase Auth. A matching `profiles` record should appear automatically.
6. Run `tests/database_smoke_test.sql` in the SQL Editor of your development project. It uses temporary test users inside a rolled-back transaction; no test accounts or records are retained. Sequence counters can advance.

Alternatively, use the Supabase CLI migration workflow after initializing and linking the intended project. Do not mix SQL Editor application with CLI migration deployment without reconciling migration history.

## Tables and app mapping

| Architecture entity | Supabase table | Notes |
| --- | --- | --- |
| User | `auth.users` + `public.profiles` | Auth owns email/password; profile owns full name, phone and address |
| Transaction | `transactions` | Amount, date, type, category and owner |
| Budget | `budgets` | One positive budget per owner/month; month is the first day |
| Category | `categories` | Shared income/expense categories |
| Keyword | `keywords` | Shared expense-category matching dictionary |
| Recommendation | `recommendations` | Generated monthly results, unique by owner/month/rule |
| Risk Alert | `risk_alerts` | Generated monthly warnings/high risks, rules or future ML source |

Amounts are positive MYR values; `transaction_type` distinguishes income from expense. Category/type foreign keys prevent using an income category for an expense. IDs are database-generated bigint values. The repository maps category IDs to names, `transaction_type` to `income`, and `full_name` to `name`. Email comes from Auth and is read-only in the profile editor.

## Access rules

- Unauthenticated clients cannot read app tables.
- Signed-in users can read/update their own profile and create/read/update/delete their own transactions and budgets. Owners cannot be reassigned to other users.
- Signed-in users can read categories and keywords but cannot change them.
- Recommendation and alert records are readable only by their owner. The `persist_monthly_insights` migration installs private database triggers to generate results; clients cannot write these tables or call the private generators.
- `expense_tracker_month_summary(p_month)` returns income, expenses, balance, budget and remaining budget under the caller's RLS policies. A missing budget defaults to RM 1,500, matching the current app.
- Account deletion cascades to its app records. Profile deletion is not granted to the client.

The mobile app must use the project's public/publishable client key with Supabase Auth. Never embed a service-role or secret key in Flutter. A public key alone does not authenticate a user or bypass these policies.

## Run and verify the connected app

New registrations now return to Login (any automatic signup session is signed out). After the first explicit login, new users enter their expected monthly income and current-month spending budget. Income and setup completion are stored in Auth user metadata; the budget uses the existing owner-scoped budgets table. Metadata is only a preference, not an RLS authorization claim. Existing accounts without the new onboarding marker are not forced to repeat setup. No schema migration is required.

1. Run `flutter pub get`, then stop and run the app again (native dependencies were added; hot reload alone is insufficient).
2. Register with an email you control. If confirmation is enabled, open the confirmation email, then return to the app and log in. Delivery/redirect settings are managed in Supabase Auth; configure production email delivery and redirect URLs before release.
3. Add income/expense records, update the monthly budget and edit the profile. Restart the app and confirm the saved records reload.
4. Log out and sign in with another account; the other account must not see the first account's data.

The defaults in `lib/config/supabase_config.dart` contain only the project's public URL and publishable key. Override with `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` for a different project with the same schema. Never use a service-role or secret key in the app. The SDK persists and refreshes Auth sessions; logout clears the local session and account cache.

Automated mock tests do not send confirmation emails. The live emulator test in `integration_test/transactions_live_test.dart` checks saving and reading actual records and insights, then restores the budget and removes temporary transactions. `tests/insights_regression.sql` checks thresholds, moved/deleted transactions and owner access inside a rolled-back transaction.

## Persisted recommendations and risk alerts

Apply both migrations in order to new projects. `20261029091953_persist_monthly_insights.sql` is already deployed to the configured project. It backfills historical months and adds triggers for transaction and budget inserts, updates and deletes. Old and new months are refreshed when dates change. Results are unique per owner/month/rule; obsolete rules are removed. Rule-based risk rows are regenerated while any future ML rows are preserved. The default budget remains RM 1,500 when no budget record exists.

Private security-definer functions perform only internal derived-data writes, with a fixed empty search path, revoked client access, account checks and per-account transaction locks. Source writes still obey RLS. Failure during generation rolls back the source write too. Auth user metadata is never used for authorization.

The app reloads persisted insights after data changes and on login. Pull down on either insight screen to refresh changes from another device. A failed insight read shows Retry rather than a misleading empty state; it does not mark an already committed transaction as failed. Results are current snapshots, not an alert history or ML predictions.

Security advisor check on 29 October 2026 found no database-policy/function findings; it reported the existing disabled leaked-password-protection Auth setting. This integration does not change that setting.

References: [Supabase Auth profiles](https://supabase.com/docs/guides/auth/managing-user-data), [row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security), [database migrations](https://supabase.com/docs/guides/local-development/database-migrations).
