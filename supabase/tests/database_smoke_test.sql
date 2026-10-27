-- Run after the migration, in a development project's SQL Editor.
-- All test users and rows are rolled back. Identity sequences may advance.
begin;
select set_config('expense_test.user_a', gen_random_uuid()::text, true);
select set_config('expense_test.user_b', gen_random_uuid()::text, true);
insert into auth.users(id, raw_user_meta_data) values
  (current_setting('expense_test.user_a')::uuid, '{"full_name":"Schema Test A"}'::jsonb),
  (current_setting('expense_test.user_b')::uuid, '{"full_name":"Schema Test B"}'::jsonb);

do $$ begin
  if (select count(*) from public.profiles where id in (current_setting('expense_test.user_a')::uuid, current_setting('expense_test.user_b')::uuid)) <> 2 then
    raise exception 'Profile trigger failed';
  end if;
end $$;

insert into public.recommendations(user_id, month, rule_code, title, description) values
  (current_setting('expense_test.user_a')::uuid, '2026-10-01', 'test_rule', 'Test recommendation', 'Test');
insert into public.risk_alerts(user_id, month, rule_code, title, description, severity) values
  (current_setting('expense_test.user_a')::uuid, '2026-10-01', 'test_rule', 'Test alert', 'Test', 'warning');

set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('expense_test.user_a'), true);
select set_config('request.jwt.claims', json_build_object('sub', current_setting('expense_test.user_a'), 'role', 'authenticated')::text, true);

insert into public.transactions(description, amount, transaction_date, transaction_type, category_id)
select 'Schema test dinner', 25, '2026-10-12', 'expense', id from public.categories where name = 'Food' and transaction_type = 'expense';
insert into public.transactions(description, amount, transaction_date, transaction_type, category_id)
select 'Schema test salary', 100, '2026-10-12', 'income', id from public.categories where name = 'Salary' and transaction_type = 'income';
insert into public.budgets(month, amount) values ('2026-10-01', 500);
update public.profiles set phone = 'test phone' where id = (select auth.uid());

do $$
declare s record;
begin
  if (select count(*) from public.profiles) <> 1 then raise exception 'Profile ownership policy failed'; end if;
  if (select count(*) from public.recommendations) <> 1 or (select count(*) from public.risk_alerts) <> 1 then raise exception 'Owner insight read failed'; end if;
  select * into s from public.expense_tracker_month_summary('2026-10-01');
  if s.total_income <> 100 or s.total_expense <> 25 or s.balance <> 75 or s.budget_amount <> 500 or s.remaining <> 475 then raise exception 'Summary totals failed'; end if;
  begin
    insert into public.budgets(user_id, month, amount) values (current_setting('expense_test.user_b')::uuid, '2026-10-01', 500);
    raise exception 'Cross-user insert was allowed';
  exception when insufficient_privilege then null; end;
  begin
    update public.transactions set user_id = current_setting('expense_test.user_b')::uuid;
    raise exception 'Ownership reassignment was allowed';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.transactions(description, amount, transaction_type, category_id)
    select 'Invalid amount', 0, 'expense', id from public.categories where name = 'Food' and transaction_type = 'expense';
    raise exception 'Zero amount was accepted';
  exception when check_violation then null; end;
  begin
    insert into public.transactions(description, amount, transaction_type, category_id)
    select 'Wrong category', 10, 'expense', id from public.categories where name = 'Salary' and transaction_type = 'income';
    raise exception 'Income category used for expense';
  exception when foreign_key_violation then null; end;
  begin
    insert into public.budgets(month, amount) values ('2026-10-01', 600);
    raise exception 'Duplicate monthly budget was accepted';
  exception when unique_violation then null; end;
  begin
    update public.categories set name = 'Edited';
    raise exception 'Client modified categories';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.risk_alerts(user_id, month, rule_code, title, description, severity)
    values (auth.uid(), '2026-10-01', 'forged', 'Forged', 'Forged', 'high');
    raise exception 'Client generated trusted alert';
  exception when insufficient_privilege then null; end;
end $$;

-- User B must not see or change User A's rows.
select set_config('request.jwt.claim.sub', current_setting('expense_test.user_b'), true);
select set_config('request.jwt.claims', json_build_object('sub', current_setting('expense_test.user_b'), 'role', 'authenticated')::text, true);
do $$
declare affected integer; s record;
begin
  if exists(select 1 from public.transactions) or exists(select 1 from public.budgets) or exists(select 1 from public.recommendations) or exists(select 1 from public.risk_alerts) then raise exception 'Cross-user read leak'; end if;
  update public.transactions set amount = 1;
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'Cross-user update leak'; end if;
  delete from public.transactions;
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'Cross-user delete leak'; end if;
  select * into s from public.expense_tracker_month_summary('2026-10-01');
  if s.total_income <> 0 or s.total_expense <> 0 or s.budget_amount <> 1500 then raise exception 'Cross-user summary leak'; end if;
end $$;

reset role;
set local role anon;
do $$ begin
  begin
    perform 1 from public.transactions;
    raise exception 'Anonymous read allowed';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'PASS: profile trigger, CRUD/RLS isolation, validation, summary and anonymous denial' as result;
