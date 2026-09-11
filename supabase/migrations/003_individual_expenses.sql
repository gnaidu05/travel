create table if not exists public.travel_expenses (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.team_members(id) on delete cascade,
  expense_date date not null,
  expense_type text not null check (expense_type in ('Hotel','Air','Train','Road')),
  amount numeric(12,2) not null check (amount >= 0),
  college_id uuid references public.colleges(id) on delete set null,
  trip_reference text,
  notes text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists travel_expenses_member_date_idx on public.travel_expenses(member_id, expense_date);
create trigger expense_touch before update on public.travel_expenses for each row execute function public.touch_updated_at();
create trigger expense_audit after insert or update or delete on public.travel_expenses for each row execute function public.audit_change();

alter table public.travel_expenses enable row level security;
create policy "capgemini users can read expenses" on public.travel_expenses
for select to authenticated using (public.is_capgemini_user());
create policy "administrators can edit expenses" on public.travel_expenses
for all to authenticated using (public.is_admin()) with check (public.is_admin());
