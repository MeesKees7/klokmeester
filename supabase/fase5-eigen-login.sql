-- ============================================================
-- KlokMeester – Eigen login (inlognaam + wachtwoord, zonder Supabase-auth)
-- ============================================================
-- VOLGENS BESLUIT OPDRACHTGEVER (afwijking van het PRD):
--   - leerlingen/docent loggen in met inlognaam + wachtwoord;
--   - wachtwoorden staan leesbaar in de database (geen gevoelige
--     gegevens achter de login, dus geen hashing nodig);
--   - inlognaam en wachtwoord zijn hoofdlettergevoelig.
--
-- Voer dit ÉÉN keer uit in de SQL-editor. Daarna is Supabase-auth
-- niet meer nodig voor de app (het dashboard-account mag blijven staan).
-- Idempotent: opnieuw uitvoeren is veilig.
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- 1. Inloggegevens op de profieltabel
-- ------------------------------------------------------------
alter table public.km_gebruikers add column if not exists inlognaam text;
alter table public.km_gebruikers add column if not exists wachtwoord text;
create unique index if not exists km_gebruikers_inlognaam_uq
  on public.km_gebruikers (lower(inlognaam)) where inlognaam is not null;

-- Vanaf nu los van auth.users: eigen user_id's, FK's verwijderen.
do $$
declare r record;
begin
  for r in (
    select conname from pg_constraint
    where conrelid = 'public.km_gebruikers'::regclass and contype = 'f'
  ) loop
    execute 'alter table public.km_gebruikers drop constraint ' || r.conname;
  end loop;
  for r in (
    select conname from pg_constraint
    where conrelid = 'public.km_klassen'::regclass and contype = 'f'
  ) loop
    execute 'alter table public.km_klassen drop constraint ' || r.conname;
  end loop;
end $$;

alter table public.km_gebruikers alter column user_id set default gen_random_uuid();
alter table public.km_klassen
  add constraint km_klassen_docent_fk
  foreign key (docent_id) references public.km_gebruikers (user_id) on delete cascade;

-- Oude auth-trigger is niet meer nodig.
drop trigger if exists km_auth_nieuw_gebruiker on auth.users;

-- ------------------------------------------------------------
-- 2. Sessies (token na login)
-- ------------------------------------------------------------
create table if not exists public.km_sessies (
  token    uuid primary key default gen_random_uuid(),
  user_id  uuid not null references public.km_gebruikers (user_id) on delete cascade,
  aangemaakt timestamptz not null default now()
);
alter table public.km_sessies enable row level security;

-- ------------------------------------------------------------
-- 3. Helper: wie is er ingelogd (token komt uit de request-header)
-- ------------------------------------------------------------
create or replace function public.km_huidige_gebruiker()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select user_id from public.km_sessies
  where token::text = coalesce(
    current_setting('request.headers', true)::json ->> 'x-km-token', '')
  ;
$$;

create or replace function public.km_is_docent()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.km_gebruikers g
    where g.user_id = public.km_huidige_gebruiker() and g.rol = 'docent'
  );
$$;

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
    and k.docent_id = public.km_huidige_gebruiker();
$$;

-- ------------------------------------------------------------
-- 4. Login / uitloggen / profiel
-- ------------------------------------------------------------
create or replace function public.km_login(p_inlognaam text, p_wachtwoord text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  g  record;
  t  uuid;
begin
  select * into g from public.km_gebruikers
  where inlognaam = p_inlognaam      -- hoofdlettergevoelig
    and wachtwoord = p_wachtwoord;   -- hoofdlettergevoelig
  if not found then
    raise exception 'Inloggen mislukt';
  end if;
  insert into public.km_sessies (user_id) values (g.user_id)
  returning token into t;
  return json_build_object(
    'token', t, 'user_id', g.user_id,
    'roepnaam', g.roepnaam, 'rol', g.rol
  );
end;
$$;

create or replace function public.km_uitloggen()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.km_sessies
  where token::text = coalesce(
    current_setting('request.headers', true)::json ->> 'x-km-token', '');
$$;

create or replace function public.km_mijn_profiel()
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object('user_id', g.user_id, 'roepnaam', g.roepnaam, 'rol', g.rol)
  from public.km_gebruikers g
  where g.user_id = public.km_huidige_gebruiker();
$$;

-- ------------------------------------------------------------
-- 5. Beheer door de docent
-- ------------------------------------------------------------
-- De vorige versie van km_maak_leerling had een parameter p_email;
-- PostgreSQL staat geen andere parameternaam toe zonder drop.
drop function if exists public.km_maak_leerling(text, text, text);

create or replace function public.km_maak_leerling(
  p_inlognaam  text,
  p_wachtwoord text,
  p_roepnaam   text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid;
  v_klas uuid;
begin
  if not public.km_is_docent() then
    raise exception 'Alleen de docent kan accounts aanmaken';
  end if;
  if p_inlognaam is null or btrim(p_inlognaam) = ''
     or p_roepnaam is null or btrim(p_roepnaam) = ''
     or p_wachtwoord is null or p_wachtwoord = '' then
    raise exception 'Vul alles in';
  end if;
  if exists (select 1 from public.km_gebruikers where lower(inlognaam) = lower(btrim(p_inlognaam))) then
    raise exception 'Deze inlognaam bestaat al';
  end if;
  select id into v_klas from public.km_klassen
  where docent_id = public.km_huidige_gebruiker()
  order by created_at asc limit 1;
  insert into public.km_gebruikers (roepnaam, rol, klas_id, inlognaam, wachtwoord)
  values (btrim(p_roepnaam), 'leerling', v_klas, btrim(p_inlognaam), p_wachtwoord)
  returning user_id into v_user;
  return v_user;
end;
$$;

create or replace function public.km_zet_roepnaam(p_user uuid, p_roepnaam text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.km_is_docent() then raise exception 'Alleen de docent kan dit'; end if;
  if public.km_klas_van(p_user) is null then raise exception 'Niet jouw leerling'; end if;
  update public.km_gebruikers set roepnaam = btrim(p_roepnaam) where user_id = p_user;
end;
$$;

create or replace function public.km_reset_wachtwoord(p_user uuid, p_wachtwoord text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.km_is_docent() then raise exception 'Alleen de docent kan dit'; end if;
  if public.km_klas_van(p_user) is null then raise exception 'Niet jouw leerling'; end if;
  if p_wachtwoord is null or p_wachtwoord = '' then raise exception 'Leeg wachtwoord'; end if;
  update public.km_gebruikers set wachtwoord = p_wachtwoord where user_id = p_user;
end;
$$;

create or replace function public.km_verwijder_leerling(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.km_is_docent() then raise exception 'Alleen de docent kan dit'; end if;
  if public.km_klas_van(p_user) is null then raise exception 'Niet jouw leerling'; end if;
  delete from public.km_gebruikers where user_id = p_user;
end;
$$;

create or replace function public.km_bewaar_record(p_niveau int, p_sterren int)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.km_huidige_gebruiker() is null then
    raise exception 'Niet ingelogd';
  end if;
  insert into public.km_records (leerling_id, niveau, sterren)
  values (public.km_huidige_gebruiker(), p_niveau, p_sterren)
  on conflict (leerling_id, niveau)
  do update set
    sterren = greatest(public.km_records.sterren, excluded.sterren),
    updated_at = now();
end;
$$;

-- ------------------------------------------------------------
-- 6. Toegangsregels (RLS) op basis van de eigen sessie-token
-- ------------------------------------------------------------
drop policy if exists km_klassen_docent_lezen on public.km_klassen;
create policy km_klassen_docent_lezen on public.km_klassen
  for select using (docent_id = public.km_huidige_gebruiker());

drop policy if exists km_gebruikers_eigen_lezen on public.km_gebruikers;
create policy km_gebruikers_eigen_lezen on public.km_gebruikers
  for select using (user_id = public.km_huidige_gebruiker());

drop policy if exists km_gebruikers_docent_lezen on public.km_gebruikers;
create policy km_gebruikers_docent_lezen on public.km_gebruikers
  for select using (
    public.km_is_docent()
    and klas_id in (select id from public.km_klassen
                    where docent_id = public.km_huidige_gebruiker())
  );

drop policy if exists km_resultaten_eigen_invoegen on public.km_resultaten;
create policy km_resultaten_eigen_invoegen on public.km_resultaten
  for insert with check (leerling_id = public.km_huidige_gebruiker());

drop policy if exists km_resultaten_eigen_lezen on public.km_resultaten;
create policy km_resultaten_eigen_lezen on public.km_resultaten
  for select using (leerling_id = public.km_huidige_gebruiker());

drop policy if exists km_resultaten_docent_lezen on public.km_resultaten;
create policy km_resultaten_docent_lezen on public.km_resultaten
  for select using (public.km_klas_van(leerling_id) is not null);

drop policy if exists km_records_eigen_lezen on public.km_records;
create policy km_records_eigen_lezen on public.km_records
  for select using (leerling_id = public.km_huidige_gebruiker());

drop policy if exists km_records_docent_lezen on public.km_records;
create policy km_records_docent_lezen on public.km_records
  for select using (public.km_klas_van(leerling_id) is not null);

-- Verouderde policies opruimen (waren op Supabase-auth gebaseerd).
drop policy if exists km_records_eigen_schrijven on public.km_records;
drop policy if exists km_records_eigen_updaten on public.km_records;

-- ------------------------------------------------------------
-- 7. Rechten voor de anon-rol (de app gebruikt geen Supabase-auth meer)
-- ------------------------------------------------------------
grant select on public.km_gebruikers, public.km_klassen,
  public.km_resultaten, public.km_records to anon;
grant insert on public.km_resultaten to anon;
revoke all on public.km_sessies from anon, authenticated;

revoke all on function public.km_login(text, text) from public;
revoke all on function public.km_uitloggen() from public;
revoke all on function public.km_mijn_profiel() from public;
revoke all on function public.km_maak_leerling(text, text, text) from public;
revoke all on function public.km_zet_roepnaam(uuid, text) from public;
revoke all on function public.km_reset_wachtwoord(uuid, text) from public;
revoke all on function public.km_verwijder_leerling(uuid) from public;
revoke all on function public.km_bewaar_record(int, int) from public;
grant execute on function public.km_login(text, text) to anon;
grant execute on function public.km_uitloggen() to anon;
grant execute on function public.km_mijn_profiel() to anon;
grant execute on function public.km_maak_leerling(text, text, text) to anon;
grant execute on function public.km_zet_roepnaam(uuid, text) to anon;
grant execute on function public.km_reset_wachtwoord(uuid, text) to anon;
grant execute on function public.km_verwijder_leerling(uuid) to anon;
grant execute on function public.km_bewaar_record(int, int) to anon;

-- ------------------------------------------------------------
-- 8. Docentaccount + klas (zaadje)
-- ------------------------------------------------------------
-- Log daarna in met inlognaam "docent" en wachtwoord "KlokMeester!"
-- (hoofdlettergevoelig) en WIJZIG het wachtwoord via SQL hieronder.
insert into public.km_gebruikers (roepnaam, rol, inlognaam, wachtwoord)
select 'Kees', 'docent', 'docent', 'KlokMeester!'
where not exists (select 1 from public.km_gebruikers where rol = 'docent');

insert into public.km_klassen (naam, docent_id)
select 'Groep 6', g.user_id
from public.km_gebruikers g
where g.rol = 'docent'
  and not exists (
    select 1 from public.km_klassen k
    where k.docent_id = g.user_id
  );
