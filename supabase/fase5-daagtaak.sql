-- ============================================================
-- KlokMeester – Fase 5: daagtaak (niveau 11)
-- ============================================================
-- Voer dit script één keer uit in de Supabase SQL-editor, NA de
-- eerdere fase-scripts. Het is idempotent: herhaald uitvoeren is
-- veilig en verandert niets meer.
--
-- Wat het doet:
--   De daagtaak wordt opgeslagen als niveau 11. De tabellen
--   km_resultaten en km_records staan via een CHECK afgebakend tot
--   niveaus 1 t/m 10; die grens wordt hier verlegd naar 1 t/m 11.
--   Bestaande gegevens worden niet gewijzigd.
-- ============================================================

-- 1. km_resultaten: niveau 11 toestaan (CHECK kan alleen via
--    een nieuwe constraint; eerst droppen, dan opnieuw aanmaken).
alter table public.km_resultaten
  drop constraint if exists km_resultaten_niveau_check;

alter table public.km_resultaten
  add constraint km_resultaten_niveau_check
  check (niveau between 1 and 11);

-- 2. km_records: niveau 11 toestaan.
alter table public.km_records
  drop constraint if exists km_records_niveau_check;

alter table public.km_records
  add constraint km_records_niveau_check
  check (niveau between 1 and 11);
