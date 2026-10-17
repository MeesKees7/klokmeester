# AGENTS.md — Werkafspraken KlokMeester

Dit bestand beschrijft de werkafspraken voor iedereen (mens of AI-agent) die aan de
KlokMeester-oefenapp werkt. Het PRD (`prd_klokmeester.md`) is de bron van truth voor
inhoud en scope; dit bestand beschrijft hoe we werken.

## 1. Projectoverzicht

- **App:** Oefenapp klokkijken voor basisschoolleerlingen (groep 6), analoog én digitaal.
- **Stack (v1):** vanilla HTML/CSS/JS, geen frameworks en geen build-stap. JS en CSS mogen in
  aparte bestanden (bijv. `app.js`, `style.css`); andere bestanden zijn ook toegestaan.
  Fase 3 voegt Supabase (PostgreSQL + auth) toe, met hosting op Vercel/Netlify.
- **Doelgroep:** kinderen van 9–10 jaar op Chromebooks/laptops; touch (digibord, telefoon) moet altijd werken.
- **Taal:** alle UI-teksten in gewone, korte kindertaal, in het Nederlands.

## 2. Niveaustructuur (vastgesteld, wijkt af van het oorspronkelijke PRD)

| Analoog (niveau 1–5) | Minuten |
|---|---|
| 1. Hele en halve uren | 0, 30 |
| 2. Kwart voor en kwart over | 0, 15, 30, 45 |
| 3. 5 en 10 min voor/over het hele uur | 0, 5, 10, 50, 55 |
| 4. 5 en 10 min voor/over het halve uur | 20, 25, 30, 35, 40 |
| 5. Alle tijden, op de minuut | 0–59 |

| Digitaal 24-uurs (niveau 6–10) | Minuten |
|---|---|
| 6. Hele en halve uren | 0, 30 |
| 7. Kwart voor en kwart over | 0, 15, 30, 45 |
| 8. 5 en 10 min voor/over het hele uur | 0, 5, 10, 50, 55 |
| 9. 5 en 10 min voor/over het halve uur | 20, 25, 30, 35, 40 |
| 10. Alle tijden, op de minuut | 0–59 |

- Bij de digitale niveaus (6–10) is er **geen analoge klok** in beeld.
- De 24-uursnotatie gaat meteen in vanaf niveau 6; "24-uurs" hoeft dus niet in de niveau­namen.

**Daagtaak (fase 5):** niveau 11, als opvallende gouden kaart onder de twee kolommen
("⭐ Extra uitdaging"). Mix van analoog én digitaal in alle drie de toetsvormen,
willekeurig per opdracht; ca. 40% van de tijden komt uit een vaste lijst lastige tijden
(9:58, 11:59, 0:00, 0:02, 12:00, 12:58, 23:58, 17:59, 6:01), de rest is willekeurig
op de minuut. In de database is de daagtaak gewoon niveau 11
(SQL: `supabase/fase5-daagtaak.sql`, CHECK-afbakening 1–11).

## 3. Klokbegrippen (rekenmethode-conventie, hard afgesproken)

- Maximum **14 over / 14 voor**; daarna via "half":
  - 0 min → "X uur" (bij uur 0/12 altijd "12 uur", nooit "0 uur")
  - 1–14 min → "X over [uur]" (15 → "kwart over [uur]")
  - 16–29 min → "X voor half [volgend uur]"
  - 30 min → "half [volgend uur]"
  - 31–44 min → "X over half [volgend uur]"
  - 46–59 min → "X voor [volgend uur]" (45 → "kwart voor [volgend uur]")
- Dus **nooit** "22 voor half 6" of "24 over 6"; 5:38 = "8 over half 6", 6:24 = "6 voor half 7".

## 4. UI-afspraken (feedback opdrachtgever, hard afgesproken)

- **Antwoordopties:** altijd 4, in een 2×2-raster.
- **Klok:** wijzers starten exact in het middelpunt (geen staart); cijfers mogen de streepjes niet raken.
- **Startpagina:** twee kolommen **naast elkaar** (analoog met wijzerplaat-kop, digitaal met digitale klok-kop); compacte niveaukaarten met sterren.
- **Tijdens het oefenen:** bovenaan staat het gekozen niveau ("Analoog – niveau 3: …"), niet een algemene tekst.
- **Klaar-knop:** gecentreerd, vlak onder de (instel)klok; Enter dient ook in.
- **Instellen digitaal:** cijfers compact naast elkaar met dubbele punt uitgelijnd; uren en minuten zijn typbaar én via +/- aanpasbaar.
- **Hoofdmenu-knop:** klein en minder opvallend, rechts-onder.
- **Dagdelen** (bij digitale niveaus): niet als hint bij de opdracht ("Het is avond" bestaat niet); wél in de antwoordopties (bij ~40% van de foute opties bewust een fout dagdeel als afleider) en bij de instel-doeltekst.
- **Sessie:** 10 opdrachten, geen tijdslimiet; na elke opdracht directe feedback (groen/rood + goede antwoord bij fout); resultaatscherm met 0–3 sterren ("Nieuw record!" bij verbetering).
- Responsive: werkt op smal scherm, digibord en laptop; klik = tik (pointer events).

## 5. Technische afspraken

- Bestandsstructuur mag gesplitst worden (`index.html` + `app.js` + `style.css` e.d.); houd de bestanden klein en duidelijk benoemd.
- Geen frameworks, geen build-stap, geen npm-dependencies in v1.
- Deployen gaat via GitHub (koppeling Vercel/Netlify met de repo): push naar `main` = live.
- Voortgang tijdelijk in `localStorage` (`klokmeester_voortgang_v1`) totdat fase 3 (database) dit vervangt. Sleutel = niveau­nummer; bij wijzigingen in de niveau­indeling de opslag-key laten staan (of een nieuwe versie-suffix gebruiken).
- Gastmodus slaat niets op (ook niet na fase 3).
- Fase 3 en later: Supabase (Postgres); rollen `leerling` en `docent`; datastructuur voorbereid op meerdere docenten/klassen (docent → klas(sen) → leerlingen); AVG-minimalisatie: alleen (roep)naam, geen foto/geboortedatum; geen selfservice-registratie (kinderen <13, docent maakt accounts aan).
- **Login (besluit opdrachtgever, afwijking van het PRD):** Supabase-auth is vervangen door een eigen login met `inlognaam` + `wachtwoord` (beide hoofdlettergevoelig), leesbaar opgeslagen in `km_gebruikers` (bewuste keuze: er zit geen gevoelige informatie achter de login). Sessies lopen via `km_sessies` + de header `x-km-token`; alle toegangsregels (RLS/RPC's) controleren deze token. Docent kan inlognamen/wachtwoorden zien en printen. SQL: `supabase/fase5-eigen-login.sql`.
- **Supabase-project (aangemaakt door opdrachtgever):** URL `https://sotrwsxrcbmdwldloubb.supabase.co`
  — de REST-endpoints staan onder `/rest/v1/<tabel>`. De `anon`-API-sleutel wordt apart
  gedeeld en hoort níet hard-coded in de repo; zet die in een config/omgevingsvariabele
  (bijv. `supabase-config.js` die op `.gitignore` staat, of de Vercel/Netlify-omgeving).

## 6. Werkwijze

- **Per fase bouwen, testen, feedback verwerken** (zie faseplan in het PRD). Bijsturen vóór de volgende fase.
- **Feedback van de opdrachtgever (Kees) gaat vóór het PRD** als ze elkaar tegenspreken; documenteer de afwijking (zoals boven gebeurd is).
- **Verificatie:** tijdgeneratie, woordvormen en optie-generatie worden gesimuleerd (Node one-liner) bij elke wijziging daarin; eis: 0 fouten over ≥100.000 gegenereerde gevallen (uniek, juist, geen verboden patronen).
- **Commits:** klein en gericht, in het Nederlands, voorvoegsel met de fase ("Fase 2 feedback: …").
- **Branches:** werk op een `vibe/...`-branch, push, en merge (fast-forward) naar `main`. `main` is altijd werkend/deploybaar.
- **Merge-beleid (afgesproken met de opdrachtgever):** na een afgeronde taak **direct** fast-forward mergen naar `main` en pushen, zonder aparte akkoordronde; Netlify zet de wijziging live. Feedback van de opdrachtgever wordt daarna verwerkt in een nieuwe `vibe/...`-branch.
- **Geen scope-creep:** alles wat het PRD bewust níet in v1 heeft (badges, leaderboard, adaptieve moeilijkheid, foutenanalyse) komt er niet zomaar bij.

## 7. Volgende stappen (stand van zaken)

1. ✅ Fase 1 — klok + niveau 1 (klaar, getest).
2. ✅ Fase 2 — 10 niveaus, 3 toetsvormen, sterren, startpagina (klaar, meerdere feedbackrondes verwerkt).
3. ✅ Fase 3 — Supabase + auth + accounts + resultaten bewaren; gastmodus blijft permanent.
   Leerlingaccounts worden door de docent in de app aangemaakt (`km_maak_leerling`);
   het docentaccount zelf is eenmalig via het Supabase-dashboard gemaakt.
4. ✅ Fase 4 — docentdashboard: resultaten per leerling, roepnaam wijzigen,
   wachtwoord resetten, verwijderen, printbaar inlogoverzicht (SQL: `supabase/fase4-beheer.sql`).
   Login is een eigen systeem (inlognaam+wachtwoord in `km_gebruikers`), geen Supabase-auth
   (SQL: `supabase/fase5-eigen-login.sql`).
5. 🔨 Fase 5 — daagtaak (niveau 11, SQL: `supabase/fase5-daagtaak.sql`),
   kindvriendelijke polish, docentenhandleiding (`docentenhandleiding.md`).
   Daarna: eindtest met echte leerlingen (pilot), dan live met groep 6.
   Verificatie van tijdgeneratie/woordvormen/opties: `node test/verificatie-fase5.mjs`.
