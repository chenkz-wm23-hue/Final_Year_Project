alter table public.transactions
  add column receipt_path text,
  add column receipt_merchant text,
  add constraint transactions_receipt_owner check (
    receipt_path is null or
    (transaction_type = 'expense' and split_part(receipt_path, '/', 1) = user_id::text
     and receipt_path ~ '^[0-9a-f-]+/[a-zA-Z0-9_-]+[.]png$')
  ),
  add constraint transactions_receipt_merchant_length check (
    receipt_merchant is null or length(receipt_merchant) <= 150
  ),
  add constraint transactions_receipt_once unique (user_id, receipt_path);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('expense-receipts', 'expense-receipts', false, 15728640, array['image/png']);

create policy receipt_owner_read on storage.objects for select to authenticated
using (bucket_id = 'expense-receipts' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy receipt_owner_insert on storage.objects for insert to authenticated
with check (bucket_id = 'expense-receipts' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy receipt_owner_update on storage.objects for update to authenticated
using (bucket_id = 'expense-receipts' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'expense-receipts' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy receipt_owner_delete on storage.objects for delete to authenticated
using (bucket_id = 'expense-receipts' and (storage.foldername(name))[1] = (select auth.uid())::text
  and not exists (select 1 from public.transactions t where t.user_id = (select auth.uid()) and t.receipt_path = name));
