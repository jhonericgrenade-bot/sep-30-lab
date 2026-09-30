-- SCHOLARTRACK: Paste this whole file in Supabase > SQL Editor > New query > Run.
-- After it runs: Authentication > Users > Add user, then login to the website.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin', 'staff', 'scholar')) default 'staff',
  created_at timestamptz default now()
);

create table if not exists public.scholarship_programs (
  id uuid primary key default gen_random_uuid(),
  program_name text not null unique,
  required_gwa numeric(3,2) not null check (required_gwa between 1 and 5),
  min_units integer not null check (min_units >= 0),
  allow_failing_grade boolean not null default false,
  active boolean not null default true,
  created_at timestamptz default now()
);

create table if not exists public.scholars (
  id uuid primary key default gen_random_uuid(),
  student_id text not null unique,
  full_name text not null,
  degree_program text not null,
  year_level integer not null check (year_level between 1 and 8),
  scholarship_id uuid not null references public.scholarship_programs(id),
  status text not null default 'Active',
  created_at timestamptz default now()
);

create table if not exists public.grade_submissions (
  id uuid primary key default gen_random_uuid(),
  scholar_id uuid not null references public.scholars(id) on delete cascade,
  academic_year text not null,
  semester text not null,
  gwa numeric(3,2) not null check (gwa between 1 and 5),
  units_enrolled integer not null check (units_enrolled >= 0),
  failed_subjects integer not null default 0 check (failed_subjects >= 0),
  incomplete_subjects integer not null default 0 check (incomplete_subjects >= 0),
  submission_status text not null default 'Pending' check (submission_status in ('Pending', 'Verified', 'Returned')),
  compliance_status text check (compliance_status in ('Compliant', 'With Deficiency')),
  deficiency_reason text,
  submitted_at timestamptz default now(),
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  unique(scholar_id, academic_year, semester)
);

-- Automatically creates a staff profile every time a user is added in Supabase Authentication.
create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)), 'staff')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute procedure public.create_profile_for_new_user();

-- Adds profiles for users created before this script was run.
insert into public.profiles (id, full_name, role)
select id, coalesce(raw_user_meta_data ->> 'full_name', split_part(email, '@', 1)), 'staff'
from auth.users on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.scholarship_programs enable row level security;
alter table public.scholars enable row level security;
alter table public.grade_submissions enable row level security;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'staff')) $$;

drop policy if exists "staff manages profiles" on public.profiles;
drop policy if exists "staff manages programs" on public.scholarship_programs;
drop policy if exists "staff manages scholars" on public.scholars;
drop policy if exists "staff manages submissions" on public.grade_submissions;

create policy "staff manages profiles" on public.profiles for all to authenticated
using (id = auth.uid() or public.is_staff()) with check (id = auth.uid() or public.is_staff());
create policy "staff manages programs" on public.scholarship_programs for all to authenticated
using (public.is_staff()) with check (public.is_staff());
create policy "staff manages scholars" on public.scholars for all to authenticated
using (public.is_staff()) with check (public.is_staff());
create policy "staff manages submissions" on public.grade_submissions for all to authenticated
using (public.is_staff()) with check (public.is_staff());

-- Optional sample program: remove the two dashes below to add it.
-- insert into public.scholarship_programs (program_name, required_gwa, min_units, allow_failing_grade)
-- values ('University Merit Scholarship', 2.50, 18, false) on conflict (program_name) do nothing;
