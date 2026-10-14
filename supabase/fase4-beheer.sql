-- ============================================================
-- KlokMeester – Fase 4: docent-beheerfuncties
-- ============================================================
-- Voer dit één keer uit in de SQL-editor, NA fase3-setup.sql
-- en fase3-beheer.sql.
--
-- Beveiligde functies die ALLEEN de ingelogde docent mag
-- aanroepen, en alleen voor leerlingen uit de eigen klas:
--   - km_zet_roepnaam:   roepnaam van een leerling wijzigen
--   - km_reset_wachtwoord: nieuw wachtwoord zetten
--   - km_verwijder_leerling: account + alle gegevens verwijderen
-- ============================================================

-- Helper: hoort deze leerling bij een klas van de ingelogde docent?
create or replace function public.km_is_eigen_leerling(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.km_klas_van(p_user) is not null;
$$;

create or replace function public.km_zet_roepnaam(p_user uuid, p_roepnaam text)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.km_is_docent() then
    raise exception 'Alleen de docent kan dit';
  end if;
  if not public.km_is_eigen_leerling(p_user) then
    raise exception 'Deze leerling zit niet in jouw klas';
  end if;
  if p_roepnaam is null or btrim(p_roepnaam) = '' then
    raise exception 'Vul een roepnaam in';
  end if;
  update public.km_gebruikers
  set roepnaam = btrim(p_roepnaam)
  where user_id = p_user;
end;
$$;

create or replace function public.km_reset_wachtwoord(p_user uuid, p_wachtwoord text)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  if not public.km_is_docent() then
    raise exception 'Alleen de docent kan dit';
  end if;
  if not public.km_is_eigen_leerling(p_user) then
    raise exception 'Deze leerling zit niet in jouw klas';
  end if;
  if p_wachtwoord is null or length(p_wachtwoord) < 6 then
    raise exception 'Kies een wachtwoord van minstens 6 tekens';
  end if;
  update auth.users
  set encrypted_password = crypt(p_wachtwoord, gen_salt('bf')),
      updated_at = now()
  where id = p_user;
end;
$$;

create or replace function public.km_verwijder_leerling(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.km_is_docent() then
    raise exception 'Alleen de docent kan dit';
  end if;
  if not public.km_is_eigen_leerling(p_user) then
    raise exception 'Deze leerling zit niet in jouw klas';
  end if;
  delete from auth.users where id = p_user;
end;
$$;

revoke all on function public.km_is_eigen_leerling(uuid) from public, anon;
revoke all on function public.km_zet_roepnaam(uuid, text) from public, anon;
revoke all on function public.km_reset_wachtwoord(uuid, text) from public, anon;
revoke all on function public.km_verwijder_leerling(uuid) from public, anon;
grant execute on function public.km_is_eigen_leerling(uuid) to authenticated;
grant execute on function public.km_zet_roepnaam(uuid, text) to authenticated;
grant execute on function public.km_reset_wachtwoord(uuid, text) to authenticated;
grant execute on function public.km_verwijder_leerling(uuid) to authenticated;

-- ============================================================
-- Fase 4 uitbreiding: inlognaam zichtbaar + signup-koppeling
-- ============================================================
-- Voer dit NA het eerste deel van dit bestand uit (of run het
-- hele bestand opnieuw; alles is idempotent).
-- ============================================================

-- 1. Inlognaam bewaren in het profiel ( Anders kan de app hem niet tonen).
alter table public.km_gebruikers
  add column if not exists inlognaam text;

-- Backfill: inlognaam invullen voor bestaande profielen.
update public.km_gebruikers g
set inlognaam = u.email
from auth.users u
where u.id = g.user_id
  and (g.inlognaam is null or g.inlognaam = '');

-- 2. Trigger bijwerken: nieuwe accounts krijgen meteen inlognaam.
create or replace function public.km_nieuw_gebruiker()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.km_gebruikers (user_id, roepnaam, rol, inlognaam)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'roepnaam', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'rol', 'leerling'),
    new.email
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- 3. Nieuwe leerling (via signup-api) aan de klas van de docent koppelen.
create or replace function public.km_koppel_aan_klas(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_klas uuid;
begin
  if not public.km_is_docent() then
    raise exception 'Alleen de docent kan dit';
  end if;
  select id into v_klas
  from public.km_klassen
  where docent_id = auth.uid()
  order by created_at asc
  limit 1;
  if v_klas is null then
    raise exception 'Er is nog geen klas; draai fase3-seed.sql';
  end if;
  update public.km_gebruikers g
  set klas_id = v_klas,
      inlognaam = (select email from auth.users u where u.id = p_user)
  where g.user_id = p_user
    and g.rol = 'leerling'
    and (g.klas_id is null or g.klas_id = v_klas);
end;
$$;

revoke all on function public.km_koppel_aan_klas(uuid) from public, anon;
grant execute on function public.km_koppel_aan_klas(uuid) to authenticated;

-- 4. Nieuw leerlingaccount direct bevestigen (email-adressen bestaan
--    niet echt; bevestiging via mail kan dus niet). Alleen de docent.
create or replace function public.km_bevestig_account(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.km_is_docent() then
    raise exception 'Alleen de docent kan dit';
  end if;
  update auth.users
  set email_confirmed_at = coalesce(email_confirmed_at, now()),
      confirmation_token = '',
      updated_at = now()
  where id = p_user;
end;
$$;

revoke all on function public.km_bevestig_account(uuid) from public, anon;
grant execute on function public.km_bevestig_account(uuid) to authenticated;
