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
