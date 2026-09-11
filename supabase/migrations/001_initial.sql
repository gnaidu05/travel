create extension if not exists pgcrypto;

create table public.team_members (
  id uuid primary key default gen_random_uuid(), source_row integer unique, full_name text not null, email text,
  city text not null, unified_grade text, category text, can_travel boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.colleges (
  id uuid primary key default gen_random_uuid(), source_row integer unique, college_name text not null,
  college_group text, college_city text, college_state text, college_zone text, category text, college_type text,
  nirf_2023 text, nirf_2024 text, nirf_2025 text, salary_bands text, hiring_type text,
  assessment_framework_1 text, assessment_framework_2 text, assessment_framework_3 text,
  registration_timeline text, hiring_date text, application_date text, application_invited text, jd_template text,
  bu_identified text, registration_date date, english_date date, assessment_date date,
  assessment_date_2 date, assessment_date_3 date, interview_date date,
  nearest_airport text, airport_distance_km numeric, nearest_station text, station_distance_km numeric,
  source_data jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.assignments (
  id uuid primary key default gen_random_uuid(), member_id uuid not null references public.team_members(id) on delete cascade,
  college_id uuid references public.colleges(id) on delete set null, assignment_date date not null,
  status text not null check(status in ('Assessment','Interview','Travel','Return','Unavailable')),
  notes text, created_by uuid default auth.uid(), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.edit_history (
  id bigint generated always as identity primary key, table_name text not null, record_id uuid not null,
  action text not null, changed_by uuid default auth.uid(), changed_at timestamptz not null default now(), old_data jsonb, new_data jsonb
);
create index assignments_date_idx on public.assignments(assignment_date);
create index assignments_member_date_idx on public.assignments(member_id, assignment_date);
create index colleges_assessment_idx on public.colleges(assessment_date);

create or replace function public.is_capgemini_user() returns boolean language sql stable security definer set search_path=public as $$
  select lower(coalesce(auth.jwt()->>'email','')) like '%@capgemini.com';
$$;
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
create or replace function public.audit_change() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into edit_history(table_name,record_id,action,old_data,new_data) values(TG_TABLE_NAME,coalesce(new.id,old.id),TG_OP,to_jsonb(old),to_jsonb(new)); return coalesce(new,old); end $$;
create trigger team_touch before update on team_members for each row execute function touch_updated_at();
create trigger college_touch before update on colleges for each row execute function touch_updated_at();
create trigger assignment_touch before update on assignments for each row execute function touch_updated_at();
create trigger team_audit after insert or update or delete on team_members for each row execute function audit_change();
create trigger college_audit after insert or update or delete on colleges for each row execute function audit_change();
create trigger assignment_audit after insert or update or delete on assignments for each row execute function audit_change();

alter table team_members enable row level security; alter table colleges enable row level security; alter table assignments enable row level security; alter table edit_history enable row level security;
create policy "authenticated domain can read team" on team_members for select to authenticated using (is_capgemini_user());
create policy "authenticated domain can edit team" on team_members for all to authenticated using (is_capgemini_user()) with check (is_capgemini_user());
create policy "authenticated domain can read colleges" on colleges for select to authenticated using (is_capgemini_user());
create policy "authenticated domain can edit colleges" on colleges for all to authenticated using (is_capgemini_user()) with check (is_capgemini_user());
create policy "authenticated domain can read assignments" on assignments for select to authenticated using (is_capgemini_user());
create policy "authenticated domain can edit assignments" on assignments for all to authenticated using (is_capgemini_user()) with check (is_capgemini_user());
create policy "authenticated domain can read history" on edit_history for select to authenticated using (is_capgemini_user());
