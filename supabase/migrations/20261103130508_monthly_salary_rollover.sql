-- Each source salary can produce at most one occurrence for a new month.
-- Keep the receipt of processing even if the user edits or deletes the copy.
create table expense_private.salary_occurrences (
  user_id uuid not null references public.profiles(id) on delete cascade,
  month date not null, source_id bigint not null, target_id bigint not null,
  primary key (user_id, month, source_id), unique(user_id, month, target_id)
);
create table expense_private.salary_calendar (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  through_month date not null
);
-- Start carrying salaries from the month this feature is enabled.
create table expense_private.salary_feature_start (
  singleton boolean primary key check(singleton), month date not null
);
insert into expense_private.salary_feature_start values(true,date_trunc('month',now() at time zone 'Asia/Kuala_Lumpur')::date);
revoke all on expense_private.salary_feature_start from public,anon,authenticated;
revoke all on expense_private.salary_occurrences, expense_private.salary_calendar from public,anon,authenticated;

create function expense_private.roll_salary(p_user uuid, p_current date)
returns void language plpgsql security definer set search_path = '' as $$
declare
  m date; salary_id bigint; src record; target bigint;
begin
  if p_user is null or (auth.uid() is not null and auth.uid() <> p_user) then
    raise exception 'Account mismatch' using errcode='42501';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user::text,0));
  select id into strict salary_id from public.categories where name='Salary' and transaction_type='income';
  select least(p_current, (through_month + interval '1 month')::date)
    into m from expense_private.salary_calendar where user_id=p_user;
  if m is null then
    select month into strict m from expense_private.salary_feature_start;
  end if;
  while m <= p_current loop
    for src in
      select t.id,t.description,t.amount from public.transactions t
      where t.user_id=p_user and t.category_id=salary_id and t.transaction_type='income'
        and t.transaction_date >= m - interval '1 month' and t.transaction_date < m
        and not exists (select 1 from expense_private.salary_occurrences o
          where o.user_id=p_user and o.month=m and o.source_id=t.id)
      order by t.id
    loop
      -- Reuse a salary already entered for this month, including a revised amount.
      select t.id into target from public.transactions t
        where t.user_id=p_user and t.category_id=salary_id and t.transaction_type='income'
          and t.transaction_date >= m and t.transaction_date < m + interval '1 month'
          and lower(btrim(t.description))=lower(btrim(src.description))
          and not exists(select 1 from expense_private.salary_occurrences o
            where o.user_id=p_user and o.month=m and o.target_id=t.id)
        order by (t.amount=src.amount) desc,t.id limit 1;
      if target is null then
        insert into public.transactions(user_id,category_id,transaction_type,description,amount,transaction_date)
        values(p_user,salary_id,'income',src.description,src.amount,m) returning id into target;
      end if;
      insert into expense_private.salary_occurrences(user_id,month,source_id,target_id)
        values(p_user,m,src.id,target);
    end loop;
    m := (m + interval '1 month')::date;
  end loop;
  insert into expense_private.salary_calendar values(p_user,p_current)
    on conflict(user_id) do update set through_month=excluded.through_month
    where expense_private.salary_calendar.through_month < excluded.through_month;
end;
$$;
revoke all on function expense_private.roll_salary(uuid,date) from public,anon,authenticated;

create function expense_private.refresh_my_salary() returns void
language sql security definer set search_path='' as $$
  select expense_private.roll_salary(auth.uid(),date_trunc('month',now() at time zone 'Asia/Kuala_Lumpur')::date);
$$;
revoke all on function expense_private.refresh_my_salary() from public,anon;
grant usage on schema expense_private to authenticated;
grant execute on function expense_private.refresh_my_salary() to authenticated;
create function public.refresh_monthly_salary() returns void
language sql security invoker set search_path='' as $$ select expense_private.refresh_my_salary(); $$;
revoke all on function public.refresh_monthly_salary() from public,anon;
grant execute on function public.refresh_monthly_salary() to authenticated;
