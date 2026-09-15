create table if not exists public.admin_access_requests (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid not null default auth.uid(),
  email text not null check (email = lower(email) and email like '%@capgemini.com'),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid
);

create unique index if not exists admin_access_requests_one_pending_idx
on public.admin_access_requests(requested_by)
where status = 'pending';

alter table public.admin_access_requests enable row level security;

grant select, insert on table public.admin_access_requests to authenticated;
grant update (status, reviewed_at, reviewed_by) on table public.admin_access_requests to authenticated;

drop policy if exists "users can read own admin requests" on public.admin_access_requests;
create policy "users can read own admin requests" on public.admin_access_requests
for select to authenticated
using ((select auth.uid()) = requested_by and public.is_capgemini_user());

drop policy if exists "administrators can read admin requests" on public.admin_access_requests;
create policy "administrators can read admin requests" on public.admin_access_requests
for select to authenticated
using (public.is_admin());

drop policy if exists "users can request admin access" on public.admin_access_requests;
create policy "users can request admin access" on public.admin_access_requests
for insert to authenticated
with check (
  public.is_capgemini_user()
  and (select auth.uid()) = requested_by
  and email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
  and status = 'pending'
  and reviewed_at is null
  and reviewed_by is null
);

drop policy if exists "administrators can review admin requests" on public.admin_access_requests;
create policy "administrators can review admin requests" on public.admin_access_requests
for update to authenticated
using (public.is_admin())
with check (public.is_admin() and status in ('approved', 'rejected'));
