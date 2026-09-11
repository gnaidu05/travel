create table if not exists public.admin_users (
  email text primary key check (email = lower(email) and email like '%@capgemini.com'),
  added_at timestamptz not null default now(),
  added_by uuid default auth.uid()
);

insert into public.admin_users(email)
values ('gopinathan.naidu@capgemini.com')
on conflict (email) do nothing;

alter table public.admin_users enable row level security;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path=public as $$
  select exists (
    select 1 from public.admin_users
    where email = lower(coalesce(auth.jwt()->>'email',''))
  );
$$;

create policy "capgemini users can read administrators" on public.admin_users
for select to authenticated using (public.is_capgemini_user());
create policy "administrators can add administrators" on public.admin_users
for insert to authenticated with check (public.is_admin());
create policy "administrators can remove administrators" on public.admin_users
for delete to authenticated using (public.is_admin());

drop policy if exists "authenticated domain can edit team" on public.team_members;
drop policy if exists "authenticated domain can edit colleges" on public.colleges;
drop policy if exists "authenticated domain can edit assignments" on public.assignments;

create policy "administrators can edit team" on public.team_members
for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "administrators can edit colleges" on public.colleges
for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "administrators can edit assignments" on public.assignments
for all to authenticated using (public.is_admin()) with check (public.is_admin());
