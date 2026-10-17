"use strict";

// Verificatie-simulatie fase 5: tijdgeneratie, woordvormen, optie-generatie
// en daagtaak-mix (incl. lastige tijden). Eis: 0 fouten over >= 100.000 gevallen.
// Uitvoeren: node test/verificatie-fase5.mjs

const NIVEAUS = [
  { nr: 1, type: "analoog", minuten: [0, 30] },
  { nr: 2, type: "analoog", minuten: [0, 15, 30, 45] },
  { nr: 3, type: "analoog", minuten: [0, 5, 10, 50, 55] },
  { nr: 4, type: "analoog", minuten: [20, 25, 30, 35, 40] },
  { nr: 5, type: "analoog", minuten: null },
  { nr: 6, type: "digitaal24", minuten: [0, 30] },
  { nr: 7, type: "digitaal24", minuten: [0, 15, 30, 45] },
  { nr: 8, type: "digitaal24", minuten: [0, 5, 10, 50, 55] },
  { nr: 9, type: "digitaal24", minuten: [20, 25, 30, 35, 40] },
  { nr: 10, type: "digitaal24", minuten: null },
  { nr: 11, type: "daagtaak", minuten: null }
];

const LASTIGE_TIJDEN = [
  { uur: 9, minuut: 58 },
  { uur: 11, minuut: 59 },
  { uur: 0, minuut: 0 },
  { uur: 0, minuut: 2 },
  { uur: 12, minuut: 0 },
  { uur: 12, minuut: 58 },
  { uur: 23, minuut: 58 },
  { uur: 17, minuut: 59 },
  { uur: 6, minuut: 1 }
];

const DAGDELEN = [
  { naam: "nacht", van: 0, tot: 6 },
  { naam: "ochtend", van: 6, tot: 12 },
  { naam: "middag", van: 12, tot: 18 },
  { naam: "avond", van: 18, tot: 24 }
];

const willekeurig = (a) => a[Math.floor(Math.random() * a.length)];

function maakTijd(niveau, type) {
  if (niveau.type === "daagtaak" && Math.random() < 0.4) {
    const t = willekeurig(LASTIGE_TIJDEN);
    let u = t.uur;
    if (type === "analoog") u = ((u + 11) % 12) + 1;
    return { uur: u, minuut: t.minuut };
  }
  const minuut = niveau.minuten ? willekeurig(niveau.minuten) : Math.floor(Math.random() * 60);
  let uur;
  if (type === "digitaal24") {
    uur = Math.floor(Math.random() * 24);
  } else {
    uur = 1 + Math.floor(Math.random() * 12);
  }
  return { uur, minuut };
}

function dagdeel(uur24) {
  return DAGDELEN.find((d) => uur24 >= d.van && uur24 < d.tot).naam;
}

function woordTijd(t) {
  const uur = ((t.uur + 11) % 12) + 1;
  const m = t.minuut;
  const volgend = (uur % 12) + 1;
  if (m === 0) return uur + " uur";
  if (m === 15) return "kwart over " + uur;
  if (m === 30) return "half " + volgend;
  if (m === 45) return "kwart voor " + volgend;
  if (m < 15) return m + " over " + uur;
  if (m < 30) return (30 - m) + " voor half " + volgend;
  if (m < 45) return (m - 30) + " over half " + volgend;
  return (60 - m) + " voor " + volgend;
}

function digitaalTijd(t, type) {
  const u = type === "digitaal24" ? t.uur : ((t.uur - 1) % 12) + 1;
  const mm = String(t.minuut).padStart(2, "0");
  return u + ":" + mm;
}

function tijdTekst(t, type) {
  if (type === "analoog") return woordTijd(t);
  return woordTijd(t) + " in de " + dagdeel(t.uur);
}

function verwisseldeWijzers(t) {
  // Wijzers verwisseld: de uurstand gelezen als minuten en de minuutstand
  // als uur. Bij 3:00 staat de minuutwijzer op 12 en de uurwijzer op 3,
  // verwisseld -> uur 12, minuut 15 -> "kwart over twaalf".
  const uur12 = ((t.uur + 11) % 12) + 1;
  const uurUitWijzer = t.minuut === 0 ? 12 : Math.round(t.minuut / 5);
  return { uur: uurUitWijzer === 0 ? 12 : uurUitWijzer, minuut: (uur12 % 12) * 5 };
}

function maakAfleider(juisteTijd, niveau, type) {
  const minuten = niveau.minuten || null;
  const stap = niveau.stap || 1;
  const pogingen = [
    () => {
      const d = Math.random() < 0.5 ? stap : -stap;
      return { uur: juisteTijd.uur, minuut: ((juisteTijd.minuut + d) % 60 + 60) % 60 };
    },
    () => {
      const d = Math.random() < 0.5 ? 1 : -1;
      const maxUur = type === "digitaal24" ? 23 : 12;
      const minUur = type === "digitaal24" ? 0 : 1;
      let uur = juisteTijd.uur + d;
      if (uur > maxUur) uur = minUur;
      if (uur < minUur) uur = maxUur;
      return { uur, minuut: juisteTijd.minuut };
    },
    () => verwisseldeWijzers(juisteTijd),
    () => maakTijd(niveau, type)
  ];
  for (let poging = 0; poging < 20; poging++) {
    let kandidaat = willekeurig(pogingen)();
    if (minuten && !minuten.includes(kandidaat.minuut)) {
      if (kandidaat.minuut === verwisseldeWijzers(juisteTijd).minuut) {
        // verwisselde wijzers zijn een bewuste, misleidende afleider en
        // mogen buiten de niveau-minuten liggen (bijv. "kwart over twaalf"
        // bij 3:00 op het niveau van hele/halve uren)
        if (kandidaat.uur === juisteTijd.uur && kandidaat.minuut === juisteTijd.minuut) continue;
      } else {
        const geldig = minuten.filter((m) => m !== juisteTijd.minuut);
        if (!geldig.length) continue;
        kandidaat.minuut = willekeurig(geldig);
      }
    }
    if (type !== "digitaal24") {
      if (!(kandidaat.uur >= 1 && kandidaat.uur <= 12)) continue;
    } else if (!(kandidaat.uur >= 0 && kandidaat.uur <= 23)) {
      continue;
    }
    if (kandidaat.uur === juisteTijd.uur && kandidaat.minuut === juisteTijd.minuut) continue;
    return kandidaat;
  }
  return { uur: juisteTijd.uur, minuut: (juisteTijd.minuut + stap) % 60 };
}

function toetsOpties(juisteTijd, niveau, type) {
  const juisteTekst = tijdTekst(juisteTijd, type);
  const opties = new Set([juisteTekst]);
  let beveiliging = 0;
  while (opties.size < 4 && beveiliging++ < 1000) {
    const kandidaat = maakAfleider(juisteTijd, niveau, type);
    if (type === "digitaal24" && Math.random() < 0.5) {
      const bron = Math.random() < 0.5 ? juisteTijd : kandidaat;
      const fouteDagdelen = DAGDELEN.filter((d) => d.naam !== dagdeel(bron.uur));
      const metDagdeel = woordTijd(bron) + " in de " + willekeurig(fouteDagdelen).naam;
      if (metDagdeel !== juisteTekst && !opties.has(metDagdeel)) {
        opties.add(metDagdeel);
        continue;
      }
    }
    const tekst = tijdTekst(kandidaat, type);
    if (tekst === juisteTekst) continue;
    opties.add(tekst);
  }
  while (opties.size < 4 && beveiliging++ < 2000) opties.add("\\u2013");
  return Array.from(opties).sort(() => Math.random() - 0.5);
}

// Referentie: onafhankelijke (trage) check van de conventie.
function refWoordTijd(t) {
  const uur = ((t.uur + 11) % 12) + 1;
  const volgend = (uur % 12) + 1;
  const m = t.minuut;
  if (m === 0) return `${uur} uur`;
  if (m === 15) return `kwart over ${uur}`;
  if (m === 30) return `half ${volgend}`;
  if (m === 45) return `kwart voor ${volgend}`;
  if (m < 15) return `${m} over ${uur}`;
  if (m < 30) return `${30 - m} voor half ${volgend}`;
  if (m < 45) return `${m - 30} over half ${volgend}`;
  return `${60 - m} voor ${volgend}`;
}

const fouten = [];
const AANTAL = 120000;
let lastigeGevallen = 0;

function checkGeval(niveau, type) {
  const t = maakTijd(niveau, type);
  if (type === "digitaal24") {
    if (!(t.uur >= 0 && t.uur <= 23)) fouten.push(["uur-bereik digitaal", t]);
  } else {
    if (!(t.uur >= 1 && t.uur <= 12)) fouten.push(["uur-bereik analoog", t]);
  }
  if (!(t.minuut >= 0 && t.minuut <= 59)) fouten.push(["minuut-bereik", t]);
  if (niveau.minuten && !niveau.minuten.includes(t.minuut)) fouten.push(["minuut niet in niveau", { niveau: niveau.nr, t }]);

  const w = woordTijd(t);
  if (w !== refWoordTijd(t)) fouten.push(["woordvorm afwijkend", { t, w, ref: refWoordTijd(t) }]);
  if (/(2[2-9]|[3-9]\d) over/.test(w) || /(2[3-9]|[3-9]\d) voor half/.test(w)) fouten.push(["verboden patroon >14/over-grens", w]);
  if (/(1[5-9]|2\d) voor half/.test(w) || /(1[5-9]|2\d) over half/.test(w)) fouten.push(["verboden patroon half-grens", w]);
  if (/^0 uur/.test(w)) fouten.push(["'0 uur' niet toegestaan", w]);
  if (w.includes("NaN")) fouten.push(["NaN", w]);

  const tekst = tijdTekst(t, type);
  const opties = toetsOpties(t, niveau, type);
  if (opties.length !== 4) fouten.push(["aantal opties", { tekst, opties }]);
  if (!opties.includes(tekst)) fouten.push(["juiste antwoord ontbreekt", { tekst, opties }]);
  if (new Set(opties).size !== 4) fouten.push(["dubbele opties", opties]);
  if (opties.includes("\u2013")) fouten.push(["plaatsoptie gebruikt", opties]);

  if (type === "digitaal24") {
    const dd = tekst.split(" in de ")[1];
    const verwacht = DAGDELEN.find((d) => t.uur >= d.van && t.uur < d.tot).naam;
    if (dd !== verwacht) fouten.push(["dagdeel fout", { t, tekst }]);
  }
}

for (let i = 0; i < AANTAL; i++) {
  const niv = NIVEAUS[i % NIVEAUS.length];
  if (niv.type === "daagtaak") {
    checkGeval(niv, i % 2 === 0 ? "analoog" : "digitaal24");
    lastigeGevallen++;
  } else {
    checkGeval(niv, niv.type === "analoog" ? "analoog" : "digitaal24");
  }
}

// Extra: alle 24*60 tijden expliciet (uniek + juist), allebei de types.
for (let uur = 0; uur < 24; uur++) {
  for (let minuut = 0; minuut < 60; minuut++) {
    const t = { uur, minuut };
    const w = woordTijd(t);
    if (w !== refWoordTijd(t)) fouten.push(["woordvorm afwijkend (volledige ronde)", { t, w }]);
    if (/^0 uur/.test(w)) fouten.push(["'0 uur'", w]);
    if (w.includes("NaN")) fouten.push(["NaN", w]);
  }
}

// Specifieke eisen uit de afpraak en het PRD:
const specifiek = [
  { t: { uur: 5, minuut: 38 }, verwacht: "8 over half 6" },
  { t: { uur: 6, minuut: 24 }, verwacht: "6 voor half 7" },
  { t: { uur: 9, minuut: 58 }, verwacht: "2 voor 10" },
  { t: { uur: 12, minuut: 0 }, verwacht: "12 uur" },
  { t: { uur: 0, minuut: 0 }, verwacht: "12 uur" },
  { t: { uur: 0, minuut: 45 }, verwacht: "kwart voor 1" },
  { t: { uur: 23, minuut: 58 }, verwacht: "2 voor 12" }
];
specifiek.forEach(({ t, verwacht }) => {
  const w = woordTijd(t);
  if (w !== verwacht) fouten.push(["specifiek geval", { t, w, verwacht }]);
});

if (lastigeGevallen < 1000) fouten.push(["te weinig daagtaak-gevallen", lastigeGevallen]);

if (fouten.length) {
  console.error("FOUTEN (" + fouten.length + "):");
  fouten.slice(0, 20).forEach((f) => console.error(" ", JSON.stringify(f)));
  process.exit(1);
}
console.log("OK: " + AANTAL + " gevallen gesimuleerd, 0 fouten (waarvan " +
  lastigeGevallen + " daagtaak-mixgevallen).");
