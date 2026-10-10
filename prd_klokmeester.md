
# PRD – Oefenapp Klokkijken "KlokMeester" (werktitel)

**Versie:** 1.0 · **Status:** bouwbriefing voor versie 1 · **Opdrachtgever/eigenaar:** Kees Versteeg

---

## 1. Samenvatting, doelgroep en onderwijscontext

**Samenvatting.** Een webapp waarmee basisschoolleerlingen zelfstandig klokkijken oefenen: analoog én digitaal, in opbouwende niveaus van hele uren tot alle tijden in 24-uursnotatie. Leerlingen kiezen een niveau en oefenen in sessies van 5–10 minuten. De app kan **vrij gebruikt worden zonder account** (gastmodus); alleen met een eigen account wordt de voortgang bewaard. De leerkracht beheert de klas en ziet per leerling welke niveaus zijn gedaan, de laatste score en persoonlijke records.

**Doelgroep.** Leerlingen van de basisschool, in eerste instantie groep 6 (ca. 9–10 jaar). De niveaus maken de app bruikbaar als differentiatie: zwakkere leerlingen oefenen lager, sterkere leerlingen werken tot op de minuut en aan de extra daagtaak.

**Onderwijscontext.** Gebruik op school tijdens reken-/rotatiewerk of als verlengde instructie, voornamelijk op laptops/Chromebooks. De leerkracht wil niet hoeven toe te zien op het inloggen of de werkwijze: een leerling moet na één korte uitleg zelfstandig kunnen werken. De app is nadrukkelijk een **oefenapp**, geen toetsapp: geen beoordeling door de leerkracht, wel zicht op voortgang.

---

## 2. Onderwijsdoel, leerlingrol en docentrol

### Onderwijsdoel
De leerling kan aan het einde van het oefentraject:
- analoge tijden aflezen tot op de minuut nauwkeurig;
- digitale tijden aflezen in 12-uursnotatie en (op hogere niveaus) 24-uursnotatie;
- een gegeven tijd instellen op een analoge klok (wijzers verplaatsen) en op een digitale klok;
- wisselen tussen analoog en digitaal.

### Oefenniveaus (opbouwend)
| Niveau | Inhoud |
|---|---|
| 1 | Hele en halve uren (analoog) |
| 2 | Kwartieren (kwart over, kwart voor) |
| 3 | 5-minuten (bijv. 10 over, 20 voor) |
| 4 | Alle tijden tot op de minuut (analoog) |
| 5 | Digitale klok, 12-uursnotatie: hele uren, halve uren en kwartieren benoemen en instellen |
| 6 | Digitale klok, 12-uursnotatie: alle tijden op 5 minuten nauwkeurig benoemen en instellen |
| 7 | Digitale klok, 12-uursnotatie: alle tijden benoemen en instellen |
| 8 | Digitale klok, 24-uursnotatie: hele uren, halve uren en kwartieren benoemen en instellen, met dagdelen erbij (nacht, ochtend, middag, avond) |
| 9 | Digitale klok, 24-uursnotatie: alle tijden benoemen en instellen |
| ★ Daagtaak | Extra uitdaging bovenop niveau 9: mix van alles (analoog + digitaal), incl. lastige tijden (bijv. 9:58, 12:00, 00:00) en snelheid |

### Leerlingrol
- **Kan altijd zonder account oefenen (gastmodus).** Direct aan de slag, geen inlogfrictie; de voortgang wordt dan níet bewaard. Dit is bewust: laagdrempelig oefenen belangrijker dan registratie. De app meldt dit duidelijk in gewone kindertaal ("Zonder account bewaart de app je sterren niet").
- Logt in met een eigen (door de leerkracht aangemaakt) account als de voortgang bewaard moet worden.
- Kiest zelf een niveau; de app toont welke niveaus al gedaan zijn en met welk resultaat.
- Oefent in korte reeksen; **één sessie duurt 5 tot 10 minuten** (±10 opdrachten), passend bij rotatiewerk, in drie toetsvormen:
  1. **Aanwijzen:** klok zien, juiste tijd kiezen uit opties (meerkeuze).
  2. **Instellen – analoog:** gegeven tijd (tekst of digitaal), wijzers naar de juiste stand slepen.
  3. **Instellen – digitaal:** gegeven analoge tijd, digitale tijd instellen.
- Ziet na elke opdracht direct of het goed was (met de goede antwoord bij fout), na de reeks een resultaatoverzicht met verdiende sterren (bijv. 0–3 sterren).
- Ziet zijn eigen voortgang: behaalde niveaus, sterren en persoonlijke records ("mijn beste score").

### Docentrol
- Maakt het docentaccount aan en beheert één klas (v1).
- Maakt leerlingaccounts aan (gebruikersnaam + eenvoudig wachtwoord) en kan deze aanpassen of verwijderen.
- Bekijkt per leerling: welke niveaus gedaan, laatste score per niveau, persoonlijk record.
- Gebruikt het dashboard om instructie en differentiatie te plannen (wie moet nog wat oefenen?).
- In v1 is er één docentaccount met één klas. In een **later stadium** kunnen leerkrachten een eigen account krijgen waaronder zij zelf een klas aanmaken en beheren (zie §7); de datastructuur moet daar nu al op voorbereid zijn.

---

## 3. Belangrijkste schermen en gebruikersflow

### Leerlingflow
```
Start: "Inloggen" óf "Zonder account oefenen" → Startpagina (niveaus) →
Niveau kiezen → Oefenscherm (sessie van ±10 opdrachten, 5–10 min) →
Resultaatscherm (sterren) → terug naar Startpagina (of volgende sessie)
```

| Scherm | Wat het doet |
|---|---|
| **Startscherm** | Twee duidelijke knoppen: "Inloggen" en "Zonder account oefenen" (gastmodus) |
| **Inlogscherm** | Gebruikersnaam + wachtwoord; groot, simpel, kindvriendelijk |
| **Startpagina leerling** | Overzichtskaartjes per niveau met verdiende sterren; knop daagtaak; eigen records |
| **Oefenscherm** | Grote klok + opdracht; meerkeuze-opties of instel-wijzers; directe feedback (groen/rood); voortgangsbalkje (5/10) |
| **Resultaatscherm** | Sterren, korte samenvatting, knoppen: "Nog een keer" / "Terug" |
| **Mijn voortgang** | Eenvoudige tabel/lijst: per niveau laatste score en record |

### Docentflow
```
Inloggen (docentaccount) → Dashboard → Leerling aanklikken → detail →
of: Leerlingenbeheer (toevoegen/wijzigen/wachtwoord resetten)
```

| Scherm | Wat het doet |
|---|---|
| **Docent-dashboard** | Klasoverzicht: per leerling niveaus gedaan, laatste scores, records |
| **Leerlingdetail** | Alles van één leerling onder elkaar |
| **Leerlingenbeheer** | Leerling toevoegen/wijzigen/verwijderen, wachtwoord resetten |

**Belangrijk UX-principe:** de leerling ziet nooit een docentfunctie en de docent ziet op één blik wat hij zoekt. Geen menu's met opties die er niet zijn.

---

## 4. Data die de app moet bewaren

| Gegevens | Voorbeeld | Opmerking |
|---|---|---|
| **Accounts** | docent + leerlingen (naam, gebruikersnaam, wachtwoord-hash, rol) | Docent beheert; leerlinggegevens beperkt tot (roep)naam i.v.m. AVG |
| **Klas** | 1 klas in v1 | Later: meerdere klassen, elk gekoppeld aan een docentaccount |
| **Oefenresultaten** | leerling, niveau, toetsvorm, datum, goed/totaal, sterren | Eén regel per afgeronde sessie; genoeg voor het dashboard |
| **Records per niveau** | hoogste score per leerling per niveau | Afleidbaar uit resultaten, maar apart bewaren maakt het dashboard snel en simpel |

**Gast-sessies worden niet opgeslagen.** Wie zonder account oefent, laat geen spoor na in de database (geen naam, geen resultaten). Dit is een bewuste keuze: maximaal laagdrempelig, AVG-vriendelijk, en geen rommel in het docentdashboard.

**Bewust níet opslaan in v1:** gedetailleerde foutenanalyse per opdracht (welke tijd fout), lesuren, toetsresultaten als beoordeling, persoonlijke gegevens (foto, geboortedatum). Dit houdt de app licht en AVG-vriendelijk. Foutenanalyse is een logische uitbreiding voor versie 2.

---

## 5. Technische basis

**Hosting/publicatie.** Vercel of Netlify (gekozen): gratis startniveau, HTTPS automatisch, updates via "deployen" van een nieuwe versie. De app is een webpagina die in de browser van de Chromebook werkt; geen installatie nodig. Het URL-adres is alleen bedoeld voor de eigen klas (in v1 niet publiek gepromoot, en docent-accounts beschermen het dashboard).

**Database.** Een beheerde clouddatabase in dezelfde omgeving. Aanbeveling: **Supabase (PostgreSQL)** in combinatie met Vercel — Postgres sluit aan bij jouw SQLite/MySQL-ervaring, en Supabase biedt kant-en-klare login (auth) en toegangsregels die bepalen wie welke gegevens mag lezen/schrijven. In gewone taal: vier "kaartenbakken" (accounts, klas, resultaten, records) met strenge toegangsregels: een leerling mag alleen zijn eigen resultaten zien, de docent alles van de klas.

**Login en rollen.** Twee rollen: `leerling` en `docent`. Wachtwoorden gehasht opgeslagen; de docent reset leerling-wachtwoorden. Geen e-mailverificatie of selfservice-registratie (kinderen < 13 jaar): accounts worden uitsluitend door de docent aangemaakt. Naast de accountvorm blijft de gastmodus permanent beschikbaar. In v1 is er één docentaccount; de structuur is docent → klas(sen) → leerlingen, zodat meerdere leerkrachten met elk een eigen klas later kunnen zonder herbouw.

**Opslag.** Alleen de genoemde tabelgegevens; geen bestanden/uploads in v1. De klok-wijzerstanden worden berekend, niet opgeslagen.

**Latere koppelingen.** Geen in v1, en het PRD houdt hier bewust ruimte voor: de datastructuur (leerling-ID, klas) is zo ontworpen dat een import uit een leerlingadministratiesysteem (ParnasSys/Magister) of Google-login later kan zonder herbouw. Dat is een ontwerpkeuze, geen functionaliteit in v1.

---

## 6. UI/UX-richting en mobiele aandachtspunten

### Leerlingervaring
- Grote, rustige klok als middelpunt; één opdracht per scherm; geen tijdslimiet (v1) om denktijd te gunnen.
- **Een sessie duurt 5–10 minuten** (±10 opdrachten): lang genoeg om te oefenen, kort genoeg voor rotatiewerk; het resultaatscherm is een natuurlijk stempunt ("pauze of doorgaan?").
- Directe feedback: groen = goed, rood + het goede antwoord = fout. Geen straffen, wel aanmoediging ("Nog één keer!").
- Kindertaal in korte zinnen; klokbegrippen conform de rekenmethode: "kwart over", "5 voor half".
- Gamificatie **redelijk**: sterren per niveau (0–3), zichtbare niveaus, persoonlijke records. Geen badges, avatars of streaks in v1 — dat voorkomt nu afleiding en bouwtijd, en kan later.

### Docentervaring
- Dashboard = één tabel met alles op een scherm; sorteren op naam is genoeg in v1.
- Leerlingbeheer zo simpel mogelijk: "Toevoegen" → naam + gebruikersnaam + wachtwoord klaarzetten.

### Mobiel en digibord
- Responsive ontwerp: alles werkt op smal scherm (telefoon) én op digibord; de oefenschermen zijn input-agnostisch (kliks werken ook als tik).
- Instelvormen (wijzers slepen) werken met aanraking én met muis; grote grijpbare wijzers (minimaal vingerbreedte).
- Minimale tekst per scherm; taal NL; geen pop-ups die het oefenen onderbreken.

---

## 7. Wat bewust nog níet in versie 1 hoort

- Automatische adaptieve moeilijkheid of doorgaansadvies (de leerling kiest zelf niveau in v1).
- Foutenanalyse per opdracht in het dashboard (welke tijden gingen fout).
- Verhaaltaken/contextopdrachten, tijdsduur- en verschilopdrachten.
- Luisteropdrachten (tijd horen).
- Meerdere scholen; meerdere leerkrachten die zélf een account aanmaken en daaronder een klas beheren (wel: datastructuur erop voorbereiden, zie §5).
- Koppelingen met leerlingadministratie of Google-login.
- Badges, avatars, streaks; leaderboard/klascompetitie.
- Toetsmodus met beoordeling of export naar rapport.
- Offline werken en meerdere talen.

Elk van deze punten is bewust een "later"-kandidaat; versie 2 pakt ze op in volgorde van onderwijskundige waarde.

---

## 8. Succescriteria voor versie 1

1. Een leerling uit groep 6 kan zonder hulp starten — met of zonder account — een niveau kiezen en een sessie afmaken (de stille test: één korte introductie op het bord).
2. Alle negen niveaus + daagtaak speelbaar in de drie toetsvormen (aanwijzen, analoog instellen, digitaal instellen).
3. Een sessie duurt 5–10 minuten; het resultaatscherm nodigt uit tot een natuurlijke pauze of een tweede sessie.
4. Gastgebruik werkt volledig zonder registratie en slaat géén gegevens op; dit is in gewone kindertaal gecommuniceerd.
5. Voortgang blijft bewaard na opnieuw inloggen; de leerling ziet eigen sterren en records.
6. De docent ziet per leerling niveaus gedaan + laatste score + record, en kan accounts beheren (aanmaken, wachtwoord resetten, verwijderen).
7. Werkt op Chromebook/laptop in de browser zonder installatie; bruikbaar op digibord en telefoonformaat.
8. Een sessie van ±10 opdrachten verloopt zonder vertraging of crashes; feedback is direct zichtbaar.
9. Geen persoonlijke gegevens opgeslagen die niet nodig zijn (AVG-minimalisatie).

---

## 9. Faseplan met testmomenten

> Werkwijze: na elke fase een testmoment + feedbackronde, dan pas bouwen aan de volgende fase. Bijsturen is goedkoop zolang de app nog klein is.

| Fase | Wat er gebouwd wordt | Testmoment / feedbackronde |
|---|---|---|
| **1 – Kern: de klok + één oefenvorm** | Analoog klokscherm dat elke willekeurige tijd correct tekent; oefenscherm "aanwijzen" (meerkeuze) voor niveau 1 (hele/halve uren), 10 opdrachten, directe feedback; nog **geen login/database** (tijdelijk bewaard in de browser). | **Test 1:** klokt de klok correct (elke willekeurige tijd)? Kiest de leerling antwoorden en ziet hij feedback? Controleer zelf ±20 willekeurige tijden op juistheid van wijzerstanden en kwaliteit van de meerkeuze-opties. |
| **2 – Alle niveaus en toetsvormen** | Niveaus 1 t/m 9 met juiste tijdverzamelingen per niveau (eerst analoog 1–4 afronden, daarna digitaal 5–9); toetsvormen "instellen analoog" (wijzers slepen) en "instellen digitaal"; sterren + resultaatscherm; sessie-indeling van 5–10 minuten. | **Test 2:** doorloop alle negen niveaus: zijn de aangeboden tijden per niveau consequent juist (bijv. geen 5-minutentijden in reeksen van niveau 1–2; in niveau 8 alleen hele/halve uren en kwartieren mét dagdelen)? Werkt slepen met muis én aanraking? Klopt de sessielengte (5–10 min)? |
| **3 – Login en database** | Supabase-database + auth; docentaccount; leerlingaccounts; resultaten worden opgeslagen en blijven na herinloggen bewaard. De gastmodus blijft permanent bestaan naast het inloggen: startscherm "Inloggen" of "Zonder account oefenen". | **Test 3:** maak een klas van 3 proefaccounts; log in/uit op verschillende apparaten; controleer dat resultaten bewaard blijven en dat leerling A geen gegevens van leerling B kan zien. Oefen ook als gast: werkt alles zonder account, en staat er écht niets in de database/dashboard? |
| **4 – Docentdashboard** | Klasoverzicht + leerlingdetail + leerlingenbeheer (toevoegen, wachtwoord resetten, verwijderen). | **Test 4:** zie je in één oogopslag wie welk niveau gedaan heeft? Maak, reset en verwijder een account. Vraag jezelf af: mis ik iets dat ik wekelijks écht nodig heb? |
| **5 – Daagtaak, polish en publicatie** | Daagtaak-mix bovenop niveau 9; kindvriendelijke afwerking (kleuren, teksten); vaste publieke URL met HTTPS; korte docentenhandleiding. | **Test 5:** eindtest met echte leerlingen (kleine pilot): vinden ze zonder account de weg, snappen ze de flow, is de feedback duidelijk? Daarna live met groep 6. |

---

## Fase 1 concreet: wat daarna getest moet worden

**Wat er in fase 1 komt (alleen dit, verder niets):**
- Het analoge klokscherm dat een willekeurige tijd correct tekent (grote klok, duidelijke wijzers).
- Niveau 1 (hele en halve uren): reeks van 10 opdrachten "klok zien → tijd kiezen uit 3–4 opties".
- Directe feedback per opdracht (goed/fout) en een simpel resultaatscherm.
- Nog géén login, geen database, geen niveaus 2+; voortgang tijdelijk.

**Wat jij na fase 1 test (checklist):**
1. **Correctheid klok:** laat de app ±20 willekeurige niveau-1-tijden zien; controleer elke keer dat uur- en minutenwijzer kloppen en niet verwisseld zijn (klassieke fout: de uurwijzer te precies op het uur, bijv. om half 3 staat de uurwijzer dan verkeerd pal op de 3).
2. **Kwaliteit meerkeuze:** zijn de foute opties plausibel maar duidelijk anders? Twee keer hetzelfde antwoord of twee opties die beide goed zouden moeten zijn, is een fout.
3. **Feedback:** ziet de leerling meteen of het goed was; snapt een kind van 9–10 de tekst zonder uitleg?
4. **Rust:** één opdracht per scherm, geen afleiding; voelt het tempo als oefenen en niet als een spelletje dat afdwaalt?
5. **Praktisch:** werkt het scherm op je Chromebook én op het digibord (resoluties)?

**Feedbackronde daarna:** geef per punt aan wat klopt en wat niet; bijsturen in fase 1 is nog goedkoop. Pas als de kern (klok + oefenervaring) goed voelt, bouwen we verder.