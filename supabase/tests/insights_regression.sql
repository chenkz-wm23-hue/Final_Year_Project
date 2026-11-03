begin;
-- Plant another owner's rows inside this rollback-only test to prove isolation.
insert into public.recommendations(user_id,month,rule_code,title,description)
select id,'2097-01-01','isolation_test','Other account','Must not be visible'
from public.profiles where id <> (select id from public.profiles order by id limit 1);
insert into public.risk_alerts(user_id,month,rule_code,title,description,severity)
select id,'2097-01-01','isolation_test','Other account','Must not be visible','high'
from public.profiles where id <> (select id from public.profiles order by id limit 1);
select set_config('request.jwt.claim.sub',(select id::text from public.profiles order by id limit 1),true);
set local role authenticated;
do $$
declare u uuid := auth.uid(); tid bigint; food bigint; salary bigint;
begin
  if exists(select 1 from public.transactions where user_id=u and transaction_date >= '2098-01-01') or
     exists(select 1 from public.budgets where user_id=u and month >= '2098-01-01') then
    raise exception 'Reserved test months already contain data';
  end if;
  select id into food from public.categories where name='Food' and transaction_type='expense';
  select id into salary from public.categories where name='Salary' and transaction_type='income';
  insert into public.budgets(user_id,month,amount) values(u,'2098-01-01',100);
  insert into public.transactions(user_id,description,amount,transaction_date,transaction_type,category_id)
    values(u,'Insight rollback test',79,'2098-01-10','expense',food) returning id into tid;
  if exists(select 1 from public.risk_alerts where month='2098-01-01' and rule_code='budget') then raise exception 'Premature budget alert'; end if;
  update public.transactions set amount=80 where id=tid;
  if not exists(select 1 from public.risk_alerts where month='2098-01-01' and rule_code='budget' and severity='warning') then raise exception '80 percent alert missing'; end if;
  update public.transactions set amount=100 where id=tid;
  if not exists(select 1 from public.risk_alerts where month='2098-01-01' and rule_code='budget' and severity='high') then raise exception '100 percent alert missing'; end if;
  if (select count(*) from public.recommendations where month='2098-01-01')<>2 then raise exception 'Recommendation count mismatch'; end if;
  update public.budgets set amount=1000 where user_id=u and month='2098-01-01';
  if exists(select 1 from public.risk_alerts where month='2098-01-01' and rule_code='budget') then raise exception 'Budget change left stale alert'; end if;
  update public.budgets set amount=100 where user_id=u and month='2098-01-01';
  if (select count(*) from public.recommendations where month='2098-01-01')<>2 then raise exception 'Refresh created duplicates'; end if;
  update public.transactions set transaction_date='2098-02-01' where id=tid;
  if exists(select 1 from public.risk_alerts where month='2098-01-01') or exists(select 1 from public.recommendations where month='2098-01-01') then raise exception 'Old month stale'; end if;
  if not exists(select 1 from public.risk_alerts where month='2098-02-01' and rule_code='cash_flow') then raise exception 'New month missing'; end if;
  delete from public.transactions where id=tid;
  if exists(select 1 from public.risk_alerts where month='2098-02-01') or exists(select 1 from public.recommendations where month='2098-02-01') then raise exception 'Deleted transaction insights stale'; end if;
  insert into public.transactions(user_id,description,amount,transaction_date,transaction_type,category_id)
    values(u,'Income rollback test',200,'2098-01-10','income',salary) returning id into tid;
  if not exists(select 1 from public.recommendations where month='2098-01-01' and rule_code='balance') then raise exception 'Income recommendation missing'; end if;
  if exists(select 1 from public.recommendations where user_id<>u) or exists(select 1 from public.risk_alerts where user_id<>u) then raise exception 'RLS account leak'; end if;
  begin
    insert into public.recommendations(user_id,month,rule_code,title,description) values(u,'2098-01-01','fake','fake','fake');
    raise exception 'Direct client insert allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    perform expense_private.refresh_insights(u,'2098-01-01');
    raise exception 'Private generator exposed';
  exception when insufficient_privilege then null;
  end;
end;
$$;
rollback;
