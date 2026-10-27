-- Smart Expense Tracker: applied migration version 20261012154113.
-- Apply once. Existing tables with these names intentionally cause an error.
begin;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text not null default '',
  address text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.profiles is 'App profile. Email and password are managed exclusively by Supabase Auth.';

create table public.categories (
  id bigint generated always as identity primary key,
  name text not null check (length(btrim(name)) > 0),
  transaction_type text not null check (transaction_type in ('income', 'expense')),
  unique (name, transaction_type),
  unique (id, transaction_type)
);

create table public.keywords (
  id bigint generated always as identity primary key,
  keyword text not null unique check (length(btrim(keyword)) > 0 and keyword = lower(btrim(keyword))),
  category_id bigint not null,
  transaction_type text not null default 'expense' check (transaction_type = 'expense'),
  foreign key (category_id, transaction_type) references public.categories(id, transaction_type)
);

create table public.transactions (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  description text not null check (length(btrim(description)) between 1 and 500),
  amount numeric(12,2) not null check (amount > 0 and amount < 'Infinity'::numeric),
  transaction_date date not null default current_date,
  transaction_type text not null check (transaction_type in ('income', 'expense')),
  category_id bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (category_id, transaction_type) references public.categories(id, transaction_type)
);

create table public.budgets (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  month date not null check (extract(day from month) = 1),
  amount numeric(12,2) not null check (amount > 0 and amount < 'Infinity'::numeric),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, month)
);

create table public.recommendations (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  month date not null check (extract(day from month) = 1),
  rule_code text not null check (length(btrim(rule_code)) > 0),
  title text not null check (length(btrim(title)) > 0),
  description text not null,
  label text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, month, rule_code)
);

create table public.risk_alerts (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  month date not null check (extract(day from month) = 1),
  rule_code text not null check (length(btrim(rule_code)) > 0),
  title text not null check (length(btrim(title)) > 0),
  description text not null,
  label text not null default '',
  severity text not null check (severity in ('warning', 'high')),
  source text not null default 'rule_based' check (source in ('rule_based', 'ml')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, month, rule_code)
);

create index transactions_user_date_idx on public.transactions(user_id, transaction_date desc);
create index transactions_category_idx on public.transactions(category_id, transaction_type);
create index keywords_category_idx on public.keywords(category_id, transaction_type);
-- The unique user/month indexes above also support owner filtering on budgets and insights.

create function public.expense_tracker_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated before update on public.profiles for each row execute function public.expense_tracker_set_updated_at();
create trigger transactions_updated before update on public.transactions for each row execute function public.expense_tracker_set_updated_at();
create trigger budgets_updated before update on public.budgets for each row execute function public.expense_tracker_set_updated_at();
create trigger recommendations_updated before update on public.recommendations for each row execute function public.expense_tracker_set_updated_at();
create trigger risk_alerts_updated before update on public.risk_alerts for each row execute function public.expense_tracker_set_updated_at();

create function public.expense_tracker_handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  return new;
end;
$$;
create trigger expense_tracker_auth_user_created after insert on auth.users
for each row execute function public.expense_tracker_handle_new_user();

-- Backfill profiles if the project already has authentication users.
insert into public.profiles(id, full_name)
select id, coalesce(raw_user_meta_data ->> 'full_name', '') from auth.users
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.keywords enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.recommendations enable row level security;
alter table public.risk_alerts enable row level security;

-- Explicit grants instead of relying on Supabase's public-schema defaults.
revoke all on public.profiles, public.categories, public.keywords, public.transactions, public.budgets, public.recommendations, public.risk_alerts from anon, authenticated;
grant select on public.profiles, public.categories, public.keywords, public.transactions, public.budgets, public.recommendations, public.risk_alerts to authenticated;
grant update (full_name, phone, address) on public.profiles to authenticated;
grant insert, update, delete on public.transactions, public.budgets to authenticated;
grant all on public.profiles, public.categories, public.keywords, public.transactions, public.budgets, public.recommendations, public.risk_alerts to service_role;
grant usage, select on sequence public.transactions_id_seq, public.budgets_id_seq to authenticated;
grant usage, select on sequence public.categories_id_seq, public.keywords_id_seq, public.transactions_id_seq, public.budgets_id_seq, public.recommendations_id_seq, public.risk_alerts_id_seq to service_role;
revoke all on function public.expense_tracker_handle_new_user() from public, anon, authenticated;
revoke all on function public.expense_tracker_set_updated_at() from public, anon, authenticated;

create policy profiles_read_own on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy categories_read on public.categories for select to authenticated using (true);
create policy keywords_read on public.keywords for select to authenticated using (true);
create policy transactions_read_own on public.transactions for select to authenticated using (user_id = (select auth.uid()));
create policy transactions_insert_own on public.transactions for insert to authenticated with check (user_id = (select auth.uid()));
create policy transactions_update_own on public.transactions for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy transactions_delete_own on public.transactions for delete to authenticated using (user_id = (select auth.uid()));
create policy budgets_read_own on public.budgets for select to authenticated using (user_id = (select auth.uid()));
create policy budgets_insert_own on public.budgets for insert to authenticated with check (user_id = (select auth.uid()));
create policy budgets_update_own on public.budgets for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy budgets_delete_own on public.budgets for delete to authenticated using (user_id = (select auth.uid()));
-- Generated insights are readable by their owner, writable only by trusted backend jobs.
create policy recommendations_read_own on public.recommendations for select to authenticated using (user_id = (select auth.uid()));
create policy risk_alerts_read_own on public.risk_alerts for select to authenticated using (user_id = (select auth.uid()));

insert into public.categories(name, transaction_type) values
  ('Food','expense'), ('Shopping','expense'), ('Transport','expense'), ('Fuel','expense'),
  ('Healthcare','expense'), ('Entertainment','expense'), ('Others','expense'),
  ('Salary','income'), ('Allowance','income'), ('Scholarship','income'), ('Freelance','income'), ('Others','income');

insert into public.keywords(keyword, category_id)
select seed.keyword, c.id from (values
  ('kfc','Food'), ('mcdonald','Food'), ('starbucks','Food'), ('dinner','Food'), ('lunch','Food'), ('food','Food'),
  ('grab','Transport'), ('rapidkl','Transport'), ('train','Transport'), ('bus','Transport'),
  ('shell','Fuel'), ('petronas','Fuel'), ('fuel','Fuel'),
  ('shopee','Shopping'), ('lazada','Shopping'), ('shopping','Shopping'),
  ('watsons','Healthcare'), ('pharmacy','Healthcare'), ('clinic','Healthcare'),
  ('netflix','Entertainment'), ('cinema','Entertainment'), ('spotify','Entertainment')
) as seed(keyword, category_name)
join public.categories c on c.name = seed.category_name and c.transaction_type = 'expense';

-- Security-invoker RPC: all aggregates obey caller RLS policies.
create function public.expense_tracker_month_summary(p_month date)
returns table (total_income numeric, total_expense numeric, balance numeric, budget_amount numeric, remaining numeric)
language sql stable security invoker set search_path = '' as $$
  with bounds as (
    select date_trunc('month', p_month)::date as start_date,
           (date_trunc('month', p_month) + interval '1 month')::date as end_date
  ), totals as (
    select coalesce(sum(t.amount) filter (where t.transaction_type = 'income'), 0) as income,
           coalesce(sum(t.amount) filter (where t.transaction_type = 'expense'), 0) as expense
    from public.transactions t cross join bounds b
    where t.user_id = (select auth.uid()) and t.transaction_date >= b.start_date and t.transaction_date < b.end_date
  ), budget as (
    select coalesce((select amount from public.budgets where user_id = (select auth.uid()) and month = (select start_date from bounds)), 1500) as amount
  )
  select t.income, t.expense, t.income - t.expense, b.amount, b.amount - t.expense from totals t cross join budget b;
$$;
revoke all on function public.expense_tracker_month_summary(date) from public, anon;
grant execute on function public.expense_tracker_month_summary(date) to authenticated;

commit;
