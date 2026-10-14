"use strict";

// Fase 3 – auth & opslag via Supabase (REST, geen libraries).
// Vereist supabase-config.js (niet in de repo) met window.SUPABASE_CONFIG.

const Auth = (() => {
  const cfgOk = typeof window.SUPABASE_CONFIG === "object" && window.SUPABASE_CONFIG;
  let sessie = null; // { token, gebruiker: { id, roepnaam, rol, email } }

  const baseUrl = () => window.SUPABASE_CONFIG.url;
  const headers = (extra) => {
    const h = {
      "apikey": window.SUPABASE_CONFIG.anonKey,
      "Content-Type": "application/json"
    };
    if (sessie && sessie.token) h["Authorization"] = "Bearer " + sessie.token;
    return Object.assign(h, extra || {});
  };

  const api = async (pad, opties) => {
    const res = await fetch(baseUrl() + pad, opties);
    if (!res.ok) {
      let detail = "";
      try { detail = (await res.json()).msg || ""; } catch {}
      throw new Error("Supabase " + res.status + (detail ? ": " + detail : ""));
    }
    return res.status === 204 ? null : res.json();
  };

  const login = async (email, wachtwoord) => {
    const data = await api("/auth/v1/token?grant_type=password", {
      method: "POST",
      headers: headers(),
      body: JSON.stringify({ email: email, password: wachtwoord })
    });
    if (!data || !data.access_token || !data.user) throw new Error("Inloggen mislukt");
    const profiel = await laadProfiel(data.access_token, data.user.id);
    sessie = {
      token: data.access_token,
      gebruiker: {
        id: data.user.id,
        email: data.user.email,
        roepnaam: profiel ? profiel.roepnaam : (data.user.email || "").split("@")[0],
        rol: profiel ? profiel.rol : "leerling"
      }
    };
    try { localStorage.setItem("klokmeester_sessie_v1", JSON.stringify({ token: data.access_token })); } catch {}
    return sessie.gebruiker;
  };

  const laadProfiel = async (token, userId) => {
    const res = await fetch(baseUrl() + "/rest/v1/km_gebruikers?select=roepnaam,rol&user_id=eq." + userId, {
      headers: { "apikey": window.SUPABASE_CONFIG.anonKey, "Authorization": "Bearer " + token }
    });
    if (!res.ok) return null;
    const rijen = await res.json();
    return rijen && rijen.length ? rijen[0] : null;
  };

  const herstelSessie = async () => {
    let bewaard = null;
    try { bewaard = JSON.parse(localStorage.getItem("klokmeester_sessie_v1")); } catch {}
    if (!bewaard || !bewaard.token) return null;
    const res = await fetch(baseUrl() + "/auth/v1/user", {
      headers: { "apikey": window.SUPABASE_CONFIG.anonKey, "Authorization": "Bearer " + bewaard.token }
    });
    if (!res.ok) {
      try { localStorage.removeItem("klokmeester_sessie_v1"); } catch {}
      return null;
    }
    const data = await res.json();
    const profiel = await laadProfiel(bewaard.token, data.id);
    sessie = {
      token: bewaard.token,
      gebruiker: {
        id: data.id,
        email: data.email,
        roepnaam: profiel ? profiel.roepnaam : (data.email || "").split("@")[0],
        rol: profiel ? profiel.rol : "leerling"
      }
    };
    return sessie.gebruiker;
  };

  const uitloggen = () => {
    sessie = null;
    try { localStorage.removeItem("klokmeester_sessie_v1"); } catch {}
  };

  const ingelogd = () => !!sessie;
  const isLeerling = () => !!(sessie && sessie.gebruiker.rol === "leerling");
  const isDocent = () => !!(sessie && sessie.gebruiker.rol === "docent");
  const gebruiker = () => (sessie ? sessie.gebruiker : null);

  // Resultaat van een afgeronde sessie opslaan (alleen voor leerlingen).
  const bewaarResultaat = async (niveau, goed, totaal, sterren) => {
    if (!isLeerling()) return false;
    try {
      await api("/rest/v1/km_resultaten", {
        method: "POST",
        headers: headers({ Prefer: "return=minimal" }),
        body: JSON.stringify({
          leerling_id: sessie.gebruiker.id,
          niveau: niveau,
          toetsvorm: "mix",
          goed: goed,
          totaal: totaal,
          sterren: sterren
        })
      });
      // Record bijwerken via RPC: alleen verbetering blijft staan.
      await api("/rest/v1/rpc/km_bewaar_record", {
        method: "POST",
        headers: headers(),
        body: JSON.stringify({ p_niveau: niveau, p_sterren: sterren })
      });
      return true;
    } catch (e) {
      console.error("Resultaat opslaan mislukt:", e);
      return false;
    }
  };

  // Records van de ingelogde leerling ophalen: { niveaunummer: sterren }.
  const laadRecords = async () => {
    if (!isLeerling()) return {};
    try {
      const rijen = await api("/rest/v1/km_records?select=niveau,sterren&leerling_id=eq." + sessie.gebruiker.id, {
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

  const maakLeerling = async (email, wachtwoord, roepnaam) => {
    if (!isDocent()) throw new Error("Alleen de docent kan dit");
    await api("/rest/v1/rpc/km_maak_leerling", {
      method: "POST",
      headers: headers(),
      body: JSON.stringify({ p_email: email, p_wachtwoord: wachtwoord, p_roepnaam: roepnaam })
    });
  };

  const laadKlas = async () => {
    if (!isDocent()) return [];
    try {
      const rijen = await api("/rest/v1/km_gebruikers?select=roepnaam&rol=eq.leerling&order=roepnaam.asc", {
        headers: headers()
      });
      return rijen || [];
    } catch (e) {
      console.error("Klas laden mislukt:", e);
      return [];
    }
  };

  return {
    beschikbaar: cfgOk,
    login,
    herstelSessie,
    uitloggen,
    ingelogd,
    isLeerling,
    isDocent,
    gebruiker,
    bewaarResultaat,
    laadRecords,
    maakLeerling,
    laadKlas
  };
})();
