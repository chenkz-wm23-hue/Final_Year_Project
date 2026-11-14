-- Savings are earmarked funds, not expenses or bank transfers.
create table public.saving_goals (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 150),
  target numeric(12,2) not null check (target > 0),
  monthly_amount numeric(12,2) not null check (monthly_amount > 0),
  start_month date not null check (extract(day from start_month)=1)
);
create table public.saving_allocations (
  user_id uuid not null references public.saving_goals(user_id) on delete cascade,
  month date not null check (extract(day from month)=1),
  amount numeric(12,2) not null check (amount > 0),
  primary key(user_id,month)
);
alter table public.saving_goals enable row level security;
alter table public.saving_allocations enable row level security;
create policy saving_goals_owner on public.saving_goals for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy saving_allocations_owner on public.saving_allocations for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
revoke all on public.saving_goals, public.saving_allocations from anon;
grant select,insert,update,delete on public.saving_goals, public.saving_allocations to authenticated;

create function public.refresh_saving_goal() returns void
language plpgsql security invoker set search_path='' as $$
declare
  g public.saving_goals; m date; total numeric; allocation numeric;
  current_month date := date_trunc('month',now() at time zone 'Asia/Kuala_Lumpur')::date;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,731));
  select * into g from public.saving_goals where user_id=auth.uid() for update;
  if not found then return; end if;
  select coalesce(sum(amount),0) into total from public.saving_allocations where user_id=auth.uid();
  select coalesce((max(month)+interval '1 month')::date,g.start_month) into m
    from public.saving_allocations where user_id=auth.uid();
  while m<=current_month and total<g.target loop
    allocation := least(g.monthly_amount,g.target-total);
    insert into public.saving_allocations values(auth.uid(),m,allocation);
    total:=total+allocation;
    m:=(m+interval '1 month')::date;
  end loop;
end;
$$;
create function public.save_saving_goal(p_name text,p_target numeric,p_monthly numeric) returns void
language plpgsql security invoker set search_path='' as $$
declare
  current_month date := date_trunc('month',now() at time zone 'Asia/Kuala_Lumpur')::date;
  previous_total numeric;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
  if p_name is null or length(btrim(p_name)) not between 1 and 150
    or p_target is null or p_monthly is null
    or p_target<=0 or p_monthly<=0 or p_target>9999999999.99 or p_monthly>9999999999.99
    or p_target<>round(p_target,2) or p_monthly<>round(p_monthly,2)
    or p_target::text='NaN' or p_monthly::text='NaN' then
    raise exception 'Invalid savings goal';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,731));
  -- Settle elapsed months at the old rate before changing the plan.
  perform public.refresh_saving_goal();
  insert into public.saving_goals values(auth.uid(),btrim(p_name),p_target,p_monthly,current_month)
    on conflict(user_id) do update set name=excluded.name,target=excluded.target,monthly_amount=excluded.monthly_amount;
  select coalesce(sum(amount),0) into previous_total from public.saving_allocations
    where user_id=auth.uid() and month<current_month;
  -- Editing or retrying replaces this month's allocation, never adds a second one.
  delete from public.saving_allocations where user_id=auth.uid() and month=current_month;
  if p_target>previous_total then
    insert into public.saving_allocations values(auth.uid(),current_month,least(p_monthly,p_target-previous_total));
  end if;
end;
$$;
revoke all on function public.refresh_saving_goal(), public.save_saving_goal(text,numeric,numeric) from public,anon;
grant execute on function public.refresh_saving_goal(), public.save_saving_goal(text,numeric,numeric) to authenticated;
