-- Isolated test account and data are discarded at the end of this transaction.
begin;
select set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
insert into auth.users(id,email) values(auth.uid(),auth.uid()::text || '@example.invalid');
set local role authenticated;
do $$
declare
  m date := date_trunc('month',now() at time zone 'Asia/Kuala_Lumpur')::date;
  s bigint := (select id from public.categories where name='Salary' and transaction_type='income');
  a bigint := (select id from public.categories where name='Allowance' and transaction_type='income');
  f bigint := (select id from public.categories where name='Food' and transaction_type='expense');
begin
  insert into public.transactions(user_id,category_id,transaction_type,description,amount,transaction_date)
  values(auth.uid(),s,'income','Main job',2300,(m-1)), (auth.uid(),s,'income','Second job',450,(m-1)),
        (auth.uid(),a,'income','Allowance',120,(m-1)), (auth.uid(),f,'expense','Dinner',30,(m-1)),
        (auth.uid(),s,'income','Main job',2500,m);
  perform public.refresh_monthly_salary();
  perform public.refresh_monthly_salary();
  if (select count(*) from public.transactions where transaction_date>=m) <> 2 or
     (select sum(amount) from public.transactions where transaction_date>=m) <> 2950 then
    raise exception 'Duplicate, missing, or incorrect income';
  end if;
  update public.transactions set amount=510 where description='Second job' and transaction_date=m;
  delete from public.transactions where description='Main job' and transaction_date=m;
  perform public.refresh_monthly_salary();
  if (select count(*) from public.transactions where transaction_date=m) <> 1 or
     (select sum(amount) from public.transactions where transaction_date=m) <> 510 then
    raise exception 'Edited or deleted salary was recreated';
  end if;
  begin
    perform expense_private.roll_salary(gen_random_uuid(),m);
    raise exception 'Private cross-account rollover exposed';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;
do $$
declare
  m date := date_trunc('month',now() at time zone 'Asia/Kuala_Lumpur')::date;
  later date := (m + interval '3 months')::date;
begin
  perform expense_private.roll_salary(auth.uid(),later);
  if (select count(*) from public.transactions where user_id=auth.uid() and transaction_date>m) <> 3 or
     (select sum(amount) from public.transactions where user_id=auth.uid() and transaction_date>m) <> 1530 then
    raise exception 'Salary did not catch up across skipped months';
  end if;
end;
$$;
rollback;
