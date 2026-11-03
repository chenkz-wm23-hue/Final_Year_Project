# Validation audit — 28 October 2026

## Results

- Android emulator `emulator-5554`, Android 17 / API 37: all 4 integration tests passed.
- Existing functional, mock-HTTP authentication and responsive layout tests: all 99 passed.
- Dart analyzer: no issues found.
- Real Android startup initialized Supabase successfully.

## On-device checks

- Login: empty email/password blocked.
- Registration: empty name, invalid email, short password and password mismatch blocked.
- Income and expense: empty descriptions and zero, negative, nonnumeric, NaN and infinite amounts blocked.
- Budget: zero, negative and nonnumeric values blocked; valid RM 800 budget saved in a local test fixture.
- Profile: whitespace-only name blocked.

Integration tests are in `integration_test/android_validation_test.dart`. Data-editing checks use an in-memory repository: no real financial records or accounts were created or modified. A pre-existing authenticated session is not logged out by the test.

## Validation gaps found (not fixed in this audit)

1. Transaction descriptions have no 500-character frontend limit. Supabase requires a trimmed description of 1–500 characters; a longer value passes the form but fails on save.
2. Transaction and budget amounts have no upper-bound validation. The database uses `numeric(12,2)` with a maximum positive value of RM 9,999,999,999.99. Larger finite values pass the form but fail on save.
3. Money fields accept more than two decimal places. For example, `0.001` passes the positive-number check, but the database rounds it to zero and rejects it. Other values may be silently rounded.
4. Optional phone numbers accept arbitrary text. Decide whether the project requires phone-format validation before imposing restrictions.

Database failures currently display a generic connection/retry message rather than explaining these invalid inputs.

## Not verified

- Successful real-account signup, email delivery, login and cross-account isolation: no verified test account was supplied. Mock-HTTP tests cover success/error handling but are not a live account test.
- Email confirmation was not disabled; the requested dashboard change was blocked pending fresh safety confirmation.

No test suite can guarantee that the app has no bugs. These results cover the cases listed above, not every possible input or network condition.
