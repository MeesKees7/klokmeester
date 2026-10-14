-- ============================================================
-- KlokMeester – Fase 3: seed (docentaccount + proefklas)
-- ============================================================
-- VANAF DEZE VERSIE: accounts worden NIET meer via SQL aangemaakt
-- (auth.users/identities zijn niet schrijfbaar vanaf de SQL-editor:
--  "must be owner of table identities").
--
-- Stappenplan:
--   1. Draai supabase/fase3-setup.sql (indien nog niet gebeurd).
--   2. Maak de accounts aan via het Supabase-dashboard:
--      Authentication → Users → "Add user"
--        - docent@klokmeester.nl    (kies eigen wachtwoord)
--        - leerling1@klokmeester.nl (kies eigen wachtwoord)
--        - leerling2@klokmeester.nl (kies eigen wachtwoord)
--        - leerling3@klokmeester.nl (kies eigen wachtwoord)
--      Zet bij elke gebruiker "Auto Confirm User" aan
--      (email-adres hoeft niet te bestaan, het dient alleen als loginnaam).
--      De trigger km_auth_nieuw_gebruiker maakt automatisch een
--      leerlingprofiel aan.
--   3. Draai DAARNA dit script: het zet de docentrol goed, maakt de
--      klas aan en koppelt de leerlingen (plus nette roepnamen).
--
-- Idempotent: opnieuw uitvoeren is veilig (doet dan niets).
-- ============================================================

-- 1. Docentprofiel juist zetten (trigger maakt eerst 'leerling' aan).
update public.km_gebruikers g
set rol = 'docent', roepnaam = 'Kees'
from auth.users u
where g.user_id = u.id
  and u.email = 'docent@klokmeester.nl'
  and g.rol <> 'docent';

-- 2. Klas aanmaken onder de docent.
insert into public.km_klassen (naam, docent_id)
select 'Groep 6', u.id
from auth.users u
where u.email = 'docent@klokmeester.nl'
  and not exists (select 1 from public.km_klassen k where k.docent_id = u.id);

-- 3. Proefleerlingen nette roepnamen geven en aan de klas koppelen.
update public.km_gebruikers g
set roepnaam = v.roepnaam,
    klas_id = k.id
from auth.users u
cross join (values
  ('leerling1@klokmeester.nl', 'Test een'),
  ('leerling2@klokmeester.nl', 'Test twee'),
  ('leerling3@klokmeester.nl', 'Test drie')
) as v(email, roepnaam)
cross join (select id from public.km_klassen limit 1) k
where g.user_id = u.id
  and u.email = v.email;
