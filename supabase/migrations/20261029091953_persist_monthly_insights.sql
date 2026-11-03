-- Derived insights are maintained atomically with their source records.
create schema if not exists expense_private;
revoke all on schema expense_private from public, anon, authenticated;

create or replace function expense_private.refresh_insights(p_user uuid, p_month date)
returns void language plpgsql security definer set search_path = '' as $$
declare
  m date := date_trunc('month', p_month)::date;
  inc numeric; exp numeric; lim numeric; c record;
begin
  -- Only internal triggers/maintenance can invoke this function. Authenticated
  -- writes are additionally restricted to their owner by source-table RLS.
  if auth.uid() is not null and auth.uid() <> p_user then
    raise exception 'Account mismatch' using errcode = '42501';
  end if;
  if not exists (select 1 from public.profiles where id = p_user) then return; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user::text, 0));
  select coalesce(sum(amount) filter (where transaction_type = 'income'),0),
         coalesce(sum(amount) filter (where transaction_type = 'expense'),0)
    into inc, exp from public.transactions
    where user_id = p_user and transaction_date >= m and transaction_date < m + interval '1 month';
  select coalesce((select amount from public.budgets where user_id = p_user and month = m),1500) into lim;

  delete from public.recommendations where user_id = p_user and month = m;
  delete from public.risk_alerts where user_id = p_user and month = m and source = 'rule_based';

  for c in
    select cat.name, sum(t.amount) as amount
    from public.transactions t join public.categories cat on cat.id = t.category_id
    where t.user_id = p_user and t.transaction_type = 'expense'
      and t.transaction_date >= m and t.transaction_date < m + interval '1 month'
    group by cat.name order by cat.name
  loop
    if (c.name = 'Food' and c.amount >= exp * .4) or (c.name = 'Shopping' and c.amount >= exp * .3) then
      insert into public.recommendations(user_id,month,rule_code,title,description,label)
      values(p_user,m,'category_' || c.name,'Review your ' || lower(c.name) || ' spending',
        c.name || ' accounts for ' || round(c.amount / exp * 100)::text || '% of expenses. Consider setting a limit for this category.',c.name);
    end if;
    if c.amount >= lim * .5 then
      insert into public.risk_alerts(user_id,month,rule_code,title,description,label,severity)
      values(p_user,m,'category_' || c.name,'High spending in ' || c.name,
        'RM ' || to_char(c.amount,'FM999999999999999990.00') || ' uses ' || round(c.amount / lim * 100)::text || '% of your monthly budget.',
        'Category alert','warning');
    end if;
  end loop;
  if exp >= lim * .8 then
    insert into public.recommendations(user_id,month,rule_code,title,description,label)
    values(p_user,m,'budget',
      case when exp >= lim then 'Revisit your monthly plan' else 'Plan your remaining expenses' end,
      case when exp > lim then 'Expenses exceed your budget by RM ' || to_char(exp-lim,'FM999999999999999990.00') || '. Review upcoming purchases.'
      else 'You have RM ' || to_char(lim-exp,'FM999999999999999990.00') || ' left in your monthly budget.' end,'Budget');
    insert into public.risk_alerts(user_id,month,rule_code,title,description,label,severity)
    values(p_user,m,'budget',
      case when exp >= lim then 'Monthly budget exceeded' else 'Approaching budget limit' end,
      'You have spent RM ' || to_char(exp,'FM999999999999999990.00') || ' of RM ' || to_char(lim,'FM999999999999999990.00') || '.',
      round(exp/lim*100)::text || '% used',case when exp >= lim then 'high' else 'warning' end);
  end if;
  if inc > exp then
    insert into public.recommendations(user_id,month,rule_code,title,description,label)
    values(p_user,m,'balance','Consider setting some money aside',
      'Income exceeds expenses by RM ' || to_char(inc-exp,'FM999999999999999990.00') || '. Account for upcoming bills before choosing an amount to save.','Monthly balance');
  elsif exp > inc then
    insert into public.risk_alerts(user_id,month,rule_code,title,description,label,severity)
    values(p_user,m,'cash_flow','Expenses exceed income',
      'Recorded expenses are RM ' || to_char(exp-inc,'FM999999999999999990.00') || ' above income this month.','Cash flow alert','high');
  end if;
end;
$$;

create or replace function expense_private.source_insights_changed()
returns trigger language plpgsql security definer set search_path = '' as $$
declare old_month date; new_month date; owner_id uuid;
begin
  owner_id := case when tg_op = 'DELETE' then old.user_id else new.user_id end;
  if auth.uid() is not null and auth.uid() <> owner_id then
    raise exception 'Account mismatch' using errcode = '42501';
  end if;
  -- Serialize source changes for each account before calculating aggregates.
  if tg_when = 'BEFORE' then
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text, 0));
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;
  if tg_op <> 'INSERT' then
    old_month := date_trunc('month',case when tg_table_name = 'transactions'
      then (to_jsonb(old)->>'transaction_date')::date else (to_jsonb(old)->>'month')::date end)::date;
    perform expense_private.refresh_insights(old.user_id,old_month);
  end if;
  if tg_op <> 'DELETE' then
    new_month := date_trunc('month',case when tg_table_name = 'transactions'
      then (to_jsonb(new)->>'transaction_date')::date else (to_jsonb(new)->>'month')::date end)::date;
    if tg_op = 'INSERT' or new_month is distinct from old_month or new.user_id is distinct from old.user_id then
      perform expense_private.refresh_insights(new.user_id,new_month);
    end if;
  end if;
  return null;
end;
$$;
revoke all on all functions in schema expense_private from public, anon, authenticated;

create trigger transactions_insight_lock before insert or update or delete on public.transactions
for each row execute function expense_private.source_insights_changed();
create trigger transactions_insight_refresh after insert or update or delete on public.transactions
for each row execute function expense_private.source_insights_changed();
create trigger budgets_insight_lock before insert or update or delete on public.budgets
for each row execute function expense_private.source_insights_changed();
create trigger budgets_insight_refresh after insert or update or delete on public.budgets
for each row execute function expense_private.source_insights_changed();

-- Populate historical months too; empty months naturally have no rows.
do $$
declare r record;
begin
  for r in
    select user_id,date_trunc('month',transaction_date)::date as month from public.transactions
    union select user_id,month from public.budgets
    union select user_id,month from public.recommendations
    union select user_id,month from public.risk_alerts
  loop
    perform expense_private.refresh_insights(r.user_id,r.month);
  end loop;
end;
$$;
