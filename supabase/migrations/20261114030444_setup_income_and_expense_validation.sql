alter table public.transactions add column setup_income boolean not null default false;
alter table public.transactions add constraint setup_income_type check(not setup_income or transaction_type='income');
create unique index transactions_one_setup_income on public.transactions(user_id) where setup_income;
create function public.record_setup_income(p_amount numeric,p_month date) returns void
language plpgsql security invoker set search_path='' as $$
declare salary_id bigint;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
  if p_amount is null or p_amount<0 or p_amount>9999999999.99 or p_amount<>round(p_amount,2)
    or p_amount::text='NaN' or p_month is null or extract(day from p_month)<>1 then
    raise exception 'Invalid setup income'; end if;
  if p_amount=0 then return; end if;
  select id into strict salary_id from public.categories where name='Salary' and transaction_type='income';
  insert into public.transactions(user_id,description,amount,transaction_date,transaction_type,category_id,setup_income)
    values(auth.uid(),'Monthly salary (account setup)',p_amount,p_month,'income',salary_id,true)
    on conflict(user_id) where setup_income do nothing;
end;
$$;
revoke all on function public.record_setup_income(numeric,date) from public,anon;
grant execute on function public.record_setup_income(numeric,date) to authenticated;

-- Enforce the same rule for every expense write, including receipt saves and API callers.
create function public.require_income_for_expense() returns trigger
language plpgsql security invoker set search_path='' as $$
declare owner_id uuid; m date;
begin
  owner_id := case when tg_op='DELETE' then old.user_id else new.user_id end;
  perform pg_advisory_xact_lock(hashtextextended(owner_id::text,732));
  if tg_op='DELETE' then return old; end if;
  if new.transaction_type='expense' then
    m:=date_trunc('month',new.transaction_date)::date;
    if not exists(select 1 from public.transactions t
      where t.user_id=new.user_id and t.transaction_type='income' and t.amount>0
      and t.transaction_date>=m and t.transaction_date<m+interval '1 month'
      and (tg_op='INSERT' or t.id<>new.id)) then
      raise exception 'Add income for this month before saving an expense.' using errcode='P0001';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.require_income_for_expense() from public,anon;
grant execute on function public.require_income_for_expense() to authenticated;
create trigger transactions_require_income before insert or update or delete on public.transactions
for each row execute function public.require_income_for_expense();
