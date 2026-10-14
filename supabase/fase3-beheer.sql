-- ============================================================
-- KlokMeester – Fase 3: docent-beheerfunctie (accounts in de app)
-- ============================================================
-- Voer dit één keer uit in de SQL-editor, NA fase3-setup.sql.
--
-- Maakt een beveiligde functie waarmee de INGELOGDE DOCENT
-- leerlingaccounts kan aanmaken vanuit de app (pagina "Leerlingen").
-- Leerlingen kunnen dit niet; de RLS blijft gewoon intact.
--
-- Het docentaccount zelf maak je één keer via het Supabase-dashboard
-- (Authentication → Users → Add user); daarna gaat alles via de app.
-- ============================================================

create extension if not exists pgcrypto;

create or replace function public.km_maak_leerling(
  p_email        text,
  p_wachtwoord   text,
  p_roepnaam     text
)
returns uuid
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_user  uuid;
  v_klas  uuid;
begin
  if not public.km_is_docent() then
    raise exception 'Alleen de docent kan accounts aanmaken';
  end if;
  if p_email is null or btrim(p_email) = '' or p_roepnaam is null or btrim(p_roepnaam) = '' then
    raise exception 'Vul een roepnaam en gebruikersnaam in';
  end if;
  if p_wachtwoord is null or length(p_wachtwoord) < 6 then
    raise exception 'Kies een wachtwoord van minstens 6 tekens';
  end if;
  if exists (select 1 from auth.users where email = lower(btrim(p_email))) then
    raise exception 'Deze gebruikersnaam bestaat al';
  end if;

  select id into v_klas
  from public.km_klassen
  where docent_id = auth.uid()
  order by created_at asc
  limit 1;

  insert into auth.users (
    id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token, email_change
  ) values (
    gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', lower(btrim(p_email)),
    crypt(p_wachtwoord, gen_salt('bf')), now(),
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object('rol', 'leerling', 'roepnaam', btrim(p_roepnaam)),
    now(), now(), '', '', ''
  )
  returning id into v_user;

  insert into public.km_gebruikers (user_id, roepnaam, rol, klas_id)
  values (v_user, btrim(p_roepnaam), 'leerling', v_klas)
  on conflict (user_id)
  do update set klas_id = coalesce(public.km_gebruikers.klas_id, excluded.klas_id),
                roepnaam = excluded.roepnaam;

  return v_user;
end;
$$;

revoke all on function public.km_maak_leerling(text, text, text) from public, anon;
grant execute on function public.km_maak_leerling(text, text, text) to authenticated;
