-- Wasl (نظام وَصل) - database setup
-- Team allow-list: only these emails can read or write anything.
create table if not exists public.team (
  email text primary key,
  name text,
  added_at timestamptz not null default now()
);
alter table public.team enable row level security;

create or replace function public.is_team() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.team where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;
grant execute on function public.is_team() to authenticated;

-- Visits: one row per visit, soft delete
create table if not exists public.visits (
  id bigint primary key,
  data jsonb not null,
  deleted boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);
alter table public.visits enable row level security;

-- Shared settings and lists (halaqat, main base, organization, question bank, settings, counter)
create table if not exists public.kv (
  key text primary key,
  value jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);
alter table public.kv enable row level security;

create or replace function public.touch_row() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end $$;
drop trigger if exists visits_touch on public.visits;
create trigger visits_touch before insert or update on public.visits for each row execute function public.touch_row();
drop trigger if exists kv_touch on public.kv;
create trigger kv_touch before insert or update on public.kv for each row execute function public.touch_row();

drop policy if exists "team select visits" on public.visits;
drop policy if exists "team insert visits" on public.visits;
drop policy if exists "team update visits" on public.visits;
create policy "team select visits" on public.visits for select to authenticated using (public.is_team());
create policy "team insert visits" on public.visits for insert to authenticated with check (public.is_team());
create policy "team update visits" on public.visits for update to authenticated using (public.is_team()) with check (public.is_team());

drop policy if exists "team select kv" on public.kv;
drop policy if exists "team insert kv" on public.kv;
drop policy if exists "team update kv" on public.kv;
create policy "team select kv" on public.kv for select to authenticated using (public.is_team());
create policy "team insert kv" on public.kv for insert to authenticated with check (public.is_team());
create policy "team update kv" on public.kv for update to authenticated using (public.is_team()) with check (public.is_team());

-- Private bucket for visit photos (max 2 MB each, images only)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "team read photos" on storage.objects;
drop policy if exists "team upload photos" on storage.objects;
drop policy if exists "team update photos" on storage.objects;
create policy "team read photos" on storage.objects for select to authenticated using (bucket_id = 'photos' and public.is_team());
create policy "team upload photos" on storage.objects for insert to authenticated with check (bucket_id = 'photos' and public.is_team());
create policy "team update photos" on storage.objects for update to authenticated using (bucket_id = 'photos' and public.is_team());

-- Tighten table privileges (RLS still applies on top)
revoke all on public.visits, public.kv, public.team from anon;
revoke delete, truncate, references, trigger on public.visits, public.kv from authenticated;
revoke all on public.team from authenticated;
notify pgrst, 'reload schema';

-- Team members are data, not schema: add them in the SQL editor, e.g.
-- insert into public.team (email, name) values ('someone@example.com', 'الاسم') on conflict (email) do nothing;
