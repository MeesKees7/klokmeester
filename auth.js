"use strict";

// Eigen login voor KlokMeester: inlognaam + wachtwoord (hoofdlettergevoelig),
// opgeslagen in de km_-tabellen. Vereist supabase-config.js (niet in de repo)
// met window.SUPABASE_CONFIG = { url, anonKey }.

const Auth = (() => {
  const cfgOk = typeof window.SUPABASE_CONFIG === "object" && window.SUPABASE_CONFIG;
  let gebruiker = null;   // { id, roepnaam, rol }
  let token = null;

  const baseUrl = () => window.SUPABASE_CONFIG.url;
  const headers = () => ({
    "apikey": window.SUPABASE_CONFIG.anonKey,
    "Content-Type": "application/json",
    "x-km-token": token || ""
  });

  const api = async (pad, opties) => {
    const res = await fetch(baseUrl() + pad, opties);
    if (!res.ok) {
      let detail = "";
      try { detail = (await res.json()).message || ""; } catch {}
      throw new Error("Supabase " + res.status + (detail ? ": " + detail : ""));
    }
    return res.status === 204 ? null : res.json();
  };

  const rpc = (naam, params) => api("/rest/v1/rpc/" + naam, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(params)
  });

  const login = async (inlognaam, wachtwoord) => {
    const data = await rpc("km_login", { p_inlognaam: inlognaam, p_wachtwoord: wachtwoord });
    if (!data || !data.token) throw new Error("Inloggen mislukt");
    token = data.token;
    gebruiker = { id: data.user_id, roepnaam: data.roepnaam, rol: data.rol };
    try { localStorage.setItem("klokmeester_token_v1", token); } catch {}
    return gebruiker;
  };

  const herstelSessie = async () => {
    let bewaard = null;
    try { bewaard = localStorage.getItem("klokmeester_token_v1"); } catch {}
    if (!bewaard) return null;
    token = bewaard;
    try {
      const profiel = await rpc("km_mijn_profiel", {});
      if (!profiel || !profiel.user_id) { uitloggen(); return null; }
      gebruiker = { id: profiel.user_id, roepnaam: profiel.roepnaam, rol: profiel.rol };
      return gebruiker;
    } catch (e) {
      uitloggen();
      return null;
    }
  };

  const uitloggen = () => {
    try { if (token) rpc("km_uitloggen", {}); } catch {}
    token = null;
    gebruiker = null;
    try { localStorage.removeItem("klokmeester_token_v1"); } catch {}
  };

  const ingelogd = () => !!gebruiker;
  const isLeerling = () => !!(gebruiker && gebruiker.rol === "leerling");
  const isDocent = () => !!(gebruiker && gebruiker.rol === "docent");
  const huidige = () => gebruiker;

  const bewaarResultaat = async (niveau, goed, totaal, sterren) => {
    if (!isLeerling()) return false;
    try {
      await api("/rest/v1/km_resultaten", {
        method: "POST",
        headers: Object.assign(headers(), { Prefer: "return=minimal" }),
        body: JSON.stringify({
          leerling_id: gebruiker.id,
          niveau: niveau,
          toetsvorm: "mix",
          goed: goed,
          totaal: totaal,
          sterren: sterren
        })
      });
      await rpc("km_bewaar_record", { p_niveau: niveau, p_sterren: sterren });
      return true;
    } catch (e) {
      console.error("Resultaat opslaan mislukt:", e);
      return false;
    }
  };

  const laadRecords = async () => {
    if (!isLeerling()) return {};
    try {
      const rijen = await api("/rest/v1/km_records?select=niveau,sterren&leerling_id=eq." + gebruiker.id, {
        headers: headers()
      });
      const map = {};
      (rijen || []).forEach((r) => { map[r.niveau] = r.sterren; });
      return map;
    } catch (e) {
      console.error("Records laden mislukt:", e);
      return {};
    }
  };

  const maakLeerling = async (inlognaam, wachtwoord, roepnaam) => {
    if (!isDocent()) throw new Error("Alleen de docent kan dit");
    return await rpc("km_maak_leerling", { p_inlognaam: inlognaam, p_wachtwoord: wachtwoord, p_roepnaam: roepnaam });
  };

  const laadKlas = async () => {
    if (!isDocent()) return [];
    try {
      const rijen = await api("/rest/v1/km_gebruikers?select=user_id,roepnaam,inlognaam,wachtwoord&rol=eq.leerling&order=roepnaam.asc", {
        headers: headers()
      });
      return rijen || [];
    } catch (e) {
      console.error("Klas laden mislukt:", e);
      return [];
    }
  };

  const laadResultaten = async (userId) => {
    try {
      const rijen = await api(
        "/rest/v1/km_resultaten?select=niveau,goed,totaal,sterren,created_at&leerling_id=eq." + userId + "&order=created_at.desc",
        { headers: headers() }
      );
      return rijen || [];
    } catch (e) {
      console.error("Resultaten laden mislukt:", e);
      return [];
    }
  };

  const zetRoepnaam = async (userId, roepnaam) => {
    await rpc("km_zet_roepnaam", { p_user: userId, p_roepnaam: roepnaam });
  };

  const resetWachtwoord = async (userId, wachtwoord) => {
    await rpc("km_reset_wachtwoord", { p_user: userId, p_wachtwoord: wachtwoord });
  };

  const verwijderLeerling = async (userId) => {
    await rpc("km_verwijder_leerling", { p_user: userId });
  };

  return {
    beschikbaar: cfgOk,
    login,
    herstelSessie,
    uitloggen,
    ingelogd,
    isLeerling,
    isDocent,
    gebruiker: huidige,
    bewaarResultaat,
    laadRecords,
    maakLeerling,
    laadKlas,
    laadResultaten,
    zetRoepnaam,
    resetWachtwoord,
    verwijderLeerling
  };
})();
