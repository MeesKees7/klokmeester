-- ============================================================
-- KlokMeester – Fase 3: database-setup (Supabase, PostgreSQL)
-- ============================================================
-- Voer dit ÉÉN keer uit in de Supabase SQL-editor
-- (Dashboard → SQL Editor → New query → plakken → Run).
--
-- Dit script:
--   1. maakt de KlokMeester-tabellen (prefix km_, zodat bestaande
--      tabellen zoals high_scores en tafelmeester onaangeroerd blijven);
--   2. zet toegangsregels (RLS): een leerling ziet alleen zijn eigen
--      gegevens, de docent alles van de eigen klas;
--   3. maakt het trigger-patroon klaar zodat accounts die later via
--      het dashboard worden aangemaakt automatisch een profiel krijgen.
--
-- Let op: dit script is idempotent voor de tabellen (IF NOT EXISTS),
-- maar de SEED (docent- en proefaccounts) staat in fase3-seed.sql en
-- hoef je ook maar één keer uit te voeren.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Tabellen
-- ------------------------------------------------------------

-- Klassen: één rij per klas. In v1 is er één klas; de koppeling
-- docent → klas → leerlingen is al voorbereid op meerdere klassen.
create table if not exists public.km_klassen (
  id         uuid primary key default gen_random_uuid(),
  naam       text not null,
  docent_id  uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Gebruikersprofielen: één rij per account (leerling of docent).
-- AVG-minimalisatie: alleen een roepnaam, verder niets.
create table if not exists public.km_gebruikers (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  roepnaam   text not null,
  rol        text not null check (rol in ('leerling', 'docent')),
  klas_id    uuid references public.km_klassen (id) on delete set null,
  created_at timestamptz not null default now()
);

-- Oefenresultaten: één rij per afgeronde sessie.
-- toetsvorm is 'mix' zolang een sessie de vormen door elkaar aanbiedt.
create table if not exists public.km_resultaten (
  id          uuid primary key default gen_random_uuid(),
  leerling_id uuid not null references public.km_gebruikers (user_id) on delete cascade,
  niveau      int  not null check (niveau between 1 and 10),
  toetsvorm   text not null default 'mix',
  goed        int  not null check (goed between 0 and 10),
  totaal      int  not null check (totaal between 1 and 10),
  sterren     int  not null check (sterren between 0 and 3),
  created_at  timestamptz not null default now()
);

-- Records: hoogste sterren per leerling per niveau (snel voor het dashboard).
create table if not exists public.km_records (
  leerling_id uuid not null references public.km_gebruikers (user_id) on delete cascade,
  niveau      int  not null check (niveau between 1 and 10),
  sterren     int  not null check (sterren between 0 and 3),
  updated_at  timestamptz not null default now(),
  primary key (leerling_id, niveau)
);

-- Index voor het docentdashboard (resultaten per klas ophalen).
create index if not exists km_resultaten_leerling_idx on public.km_resultaten (leerling_id);
create index if not exists km_gebruikers_klas_idx on public.km_gebruikers (klas_id);

-- ------------------------------------------------------------
-- 2. Row Level Security
-- ------------------------------------------------------------
alter table public.km_klassen    enable row level security;
alter table public.km_gebruikers  enable row level security;
alter table public.km_resultaten enable row level security;
alter table public.km_records    enable row level security;

-- Helper: is de ingelogde gebruiker docent?
create or replace function public.km_is_docent()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.km_gebruikers g
    where g.user_id = auth.uid() and g.rol = 'docent'
  );
$$;

-- Helper: docent-id van de klas waarin de opgegeven leerling zit
-- (null als de leerling in geen klas van de ingelogde docent zit).
create or replace function public.km_klas_van(p_leerling uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select k.id
  from public.km_gebruikers g
  join public.km_klassen k on k.id = g.klas_id
  where g.user_id = p_leerling
    and k.docent_id = auth.uid();
$$;

-- km_klassen: docent ziet eigen klassen; leerlingen geen directe toegang.
drop policy if exists km_klassen_docent_lezen on public.km_klassen;
create policy km_klassen_docent_lezen on public.km_klassen
  for select using (docent_id = auth.uid());

-- km_gebruikers: eigen profiel lezen; docent leest zijn klas;
-- invoegen/afschermen van accounts gebeurt alleen door de beheerder (seed/dashboard),
-- niet door leerlingen zelf (geen selfservice-registratie).
drop policy if exists km_gebruikers_eigen_lezen on public.km_gebruikers;
create policy km_gebruikers_eigen_lezen on public.km_gebruikers
  for select using (user_id = auth.uid());

drop policy if exists km_gebruikers_docent_lezen on public.km_gebruikers;
create policy km_gebruikers_docent_lezen on public.km_gebruikers
  for select using (
    public.km_is_docent()
    and klas_id in (select id from public.km_klassen where docent_id = auth.uid())
  );

-- km_resultaten: leerling schrijft/leest alleen eigen resultaten;
-- docent leest de resultaten van leerlingen uit eigen klas.
drop policy if exists km_resultaten_eigen_invoegen on public.km_resultaten;
create policy km_resultaten_eigen_invoegen on public.km_resultaten
  for insert with check (leerling_id = auth.uid());

drop policy if exists km_resultaten_eigen_lezen on public.km_resultaten;
create policy km_resultaten_eigen_lezen on public.km_resultaten
  for select using (leerling_id = auth.uid());

drop policy if exists km_resultaten_docent_lezen on public.km_resultaten;
create policy km_resultaten_docent_lezen on public.km_resultaten
  for select using (public.km_klas_van(leerling_id) is not null);

-- km_records: leerling schrijft/leest eigen records; docent leest klasrecords.
drop policy if exists km_records_eigen_schrijven on public.km_records;
create policy km_records_eigen_schrijven on public.km_records
  for insert with check (leerling_id = auth.uid());

drop policy if exists km_records_eigen_updaten on public.km_records;
create policy km_records_eigen_updaten on public.km_records
  for update using (leerling_id = auth.uid())
  with check (leerling_id = auth.uid());

drop policy if exists km_records_eigen_lezen on public.km_records;
create policy km_records_eigen_lezen on public.km_records
  for select using (leerling_id = auth.uid());

drop policy if exists km_records_docent_lezen on public.km_records;
create policy km_records_docent_lezen on public.km_records
  for select using (public.km_klas_van(leerling_id) is not null);

-- ------------------------------------------------------------
-- 3. Nieuw account → automatisch profiel
-- ------------------------------------------------------------
-- Als leerlingaccounts later (fase 4) via het dashboard worden aangemaakt,
-- zorgt deze functie ervoor dat het profiel meteen bestaat.
create or replace function public.km_nieuw_gebruiker()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.km_gebruikers (user_id, roepnaam, rol)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'roepnaam', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'rol', 'leerling')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists km_auth_nieuw_gebruiker on auth.users;
create trigger km_auth_nieuw_gebruiker
  after insert on auth.users
  for each row execute function public.km_nieuw_gebruiker();

-- ------------------------------------------------------------
-- 4. RPC: record bijwerken (alleen bij verbetering)
-- ------------------------------------------------------------
-- De app roept dit aan na elke sessie; greatest() zorgt ervoor
-- dat een record nooit lager wordt.
create or replace function public.km_bewaar_record(p_niveau int, p_sterren int)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Niet ingelogd';
  end if;
  insert into public.km_records (leerling_id, niveau, sterren)
  values (auth.uid(), p_niveau, p_sterren)
  on conflict (leerling_id, niveau)
  do update set
    sterren = greatest(public.km_records.sterren, excluded.sterren),
    updated_at = now();
end;
$$;

grant execute on function public.km_bewaar_record(int, int) to authenticated;
grant execute on function public.km_is_docent() to authenticated;
grant execute on function public.km_klas_van(uuid) to authenticated;
