-- ============================================================
-- KlokMeester – Fase 3: seed (docentaccount + proefklas)
-- ============================================================
-- Voer dit uit NA fase3-setup.sql, ook in de Supabase SQL-editor.
-- Maakt: 1 docentaccount, 1 klas, 3 proefleerlingen (testmoment 3).
-- Wachtwoorden hieronder zijn bedoeld voor het testmoment;
-- wijzig ze naar eigen wens vóór het uitvoeren en deel ze niet publiek.
-- Idempotent: opnieuw uitvoeren is veilig (doet dan niets).
-- ============================================================


create extension if not exists pgcrypto;


-- ------------------------------------------------------------
-- 1. Docentaccount
-- ------------------------------------------------------------
insert into auth.users (
  id, instance_id, aud, role, email,
  encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token, email_change
)
select
  gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'docent@klokmeester.nl',
  crypt('KlokDocent2024!', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"rol": "docent", "roepnaam": "Kees"}',
  now(), now(), '', '', ''
where not exists (select 1 from auth.users where email = 'docent@klokmeester.nl');

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select
  u.id, u.id, u.email,
  jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
  'email', now(), now(), now()
from auth.users u
where u.email = 'docent@klokmeester.nl'
  and not exists (select 1 from auth.identities i where i.user_id = u.id);

-- Profiel voor de docent (trigger uit fase3-setup.sql hoort dit al te doen;
-- deze insert is de vangnet voor het geval de trigger nog niet bestaat).
insert into public.km_gebruikers (user_id, roepnaam, rol)
select u.id, 'Kees', 'docent'
from auth.users u
where u.email = 'docent@klokmeester.nl'
on conflict (user_id) do nothing;

-- ------------------------------------------------------------
-- 2. Klas
-- ------------------------------------------------------------
insert into public.km_klassen (naam, docent_id)
select 'Groep 6', u.id
from auth.users u
where u.email = 'docent@klokmeester.nl'
  and not exists (select 1 from public.km_klassen k where k.docent_id = u.id);

update public.km_gebruikers g
set klas_id = k.id
from public.km_klassen k
join auth.users u on u.id = k.docent_id
where u.email = 'docent@klokmeester.nl'
  and g.user_id = u.id
  and g.klas_id is null;

-- ------------------------------------------------------------
-- 3. Drie proefleerlingen (voor testmoment 3)
-- ------------------------------------------------------------
with nieuw as (
  insert into auth.users (
    id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token, email_change
  )
  select
    gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', e,
    crypt(p, gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object('rol', 'leerling', 'roepnaam', n),
    now(), now(), '', '', ''
  from (values
    ('leerling1@klokmeester.nl', 'Test1234!', 'Test een'),
    ('leerling2@klokmeester.nl', 'Test1234!', 'Test twee'),
    ('leerling3@klokmeester.nl', 'Test1234!', 'Test drie')
  ) as t(e, p, n)
  where not exists (select 1 from auth.users u2 where u2.email = e)
  returning id, email
)
insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select id, id, email, jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true), 'email', now(), now(), now()
from nieuw;

-- Profielen + klas-koppeling voor de proefleerlingen.
insert into public.km_gebruikers (user_id, roepnaam, rol, klas_id)
select u.id, u.raw_user_meta_data ->> 'roepnaam', 'leerling', k.id
from auth.users u
cross join (select min(id) as id from public.km_klassen) k
where u.email in ('leerling1@klokmeester.nl', 'leerling2@klokmeester.nl', 'leerling3@klokmeester.nl')
  and u.raw_user_meta_data ->> 'rol' = 'leerling'
on conflict (user_id) do nothing;

update public.km_gebruikers g
set klas_id = k.id
from public.km_klassen k
where g.klas_id is null
  and g.rol = 'leerling'
  and g.user_id in (select id from auth.users where email like 'leerling%@klokmeester.nl');
