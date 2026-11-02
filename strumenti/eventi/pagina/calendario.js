// Il calendario del pannello degli eventi: come si controlla, come diventa il
// file che legge il server (server/events.go) e come si espande nelle volte.
// Lo usano la pagina (index.html) e il Worker (worker.js), che ricontrolla
// tutto prima di salvare: una sola copia delle regole.
//
// Lo stato del pannello:
//   { versione, modelli: [Modello], eventi: [Programmato] }
//   Modello     { id, nome, riga, tipo, modo (mod) | coda (gli altri), regole, premi: [{ testo, chi }] }
//   Programmato { id, modello, da, a, ogni, fino, giorni }
// da e a sono "AAAA-MM-GG HH:MM" ora di Roma, come nel file del server; ogni
// = settimane fra una volta e l'altra (0 = una volta); fino = "AAAA-MM-GG"
// o vuoto (per sempre); giorni = giorni della settimana in cui la finestra
// ricomincia (0 = lunedì), vuoto = solo il giorno di "da".
// Un programmato con i giorni diventa nel file un evento per giorno, con l'id
// e il giorno in fondo (torneo_sab): il server non sa niente dei modelli.

export const TIPI = { mod: "Modificatore", torneo: "Torneo", sfida: "Sfida", xp: "XP doppi" };
export const GIORNI = ["lun", "mar", "mer", "gio", "ven", "sab", "dom"];
const ID = /^[a-z0-9_]{1,28}$/; // il server ne vuole al massimo 32: resta posto per _lun
const DATA_ORA = /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$/;
const DATA = /^(\d{4})-(\d{2})-(\d{2})$/;
const MINUTI_SETTIMANA = 7 * 24 * 60;

// "AAAA-MM-GG HH:MM" -> minuti dal 1970 (ora del muro: come AddDate in Go,
// una settimana dopo è la stessa ora anche col cambio dell'ora legale)
export function minuti(s) {
	const m = DATA_ORA.exec(s || "");
	if (!m) return NaN;
	const t = Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]);
	const d = new Date(t);
	// 2026-02-30 non esiste: Date lo sposterebbe a marzo
	if (d.getUTCDate() !== +m[3] || d.getUTCMonth() !== +m[2] - 1) return NaN;
	return t / 60000;
}

export function scrivi(min) {
	return new Date(min * 60000).toISOString().slice(0, 16).replace("T", " ");
}

export function giornoSettimana(min) {
	return (new Date(min * 60000).getUTCDay() + 6) % 7; // 0 = lunedì
}

// adesso a Roma, come "AAAA-MM-GG HH:MM"
export function oraRoma(quando = new Date()) {
	return new Intl.DateTimeFormat("sv-SE", {
		timeZone: "Europe/Rome", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit",
	}).format(quando).replace("T", " ");
}

function intero(v, a, b) {
	return typeof v === "number" && Number.isInteger(v) && v >= a && v <= b;
}

// Le regole come client/sim/rules.lua (la lista bianca), coi dati di dati.json
function validaRegole(r, normale, dati) {
	if (typeof r !== "object" || r === null || Array.isArray(r)) return "le regole sono una tabella";
	const prim = new Set(dati.primarie), sec = new Set(dati.secondarie);
	for (const [k, v] of Object.entries(r)) {
		if (normale && !dati.coda_normale.includes(k)) return `${k}: cambia la partita, solo per i modificatori`;
		if (k === "casse") { if (!intero(v, 1, 10)) return "casse: da 1 a 10"; }
		else if (k === "cure") { if (typeof v !== "boolean") return "cure: vero o falso"; }
		else if (k === "livello") { if (v !== "fisso") return "livello: solo \"fisso\""; }
		else if (k === "tetto") { if (!intero(v, 1, dati.tetto_max)) return `tetto: da 1 a ${dati.tetto_max}`; }
		else if (k === "armi") {
			if (!Array.isArray(v) || v.length === 0) return "armi: una lista di armi";
			for (const w of v) if (!prim.has(w) && !sec.has(w)) return `armi: arma sconosciuta ${w}`;
			if (!v.some((w) => prim.has(w)) || !v.some((w) => sec.has(w))) return "armi: almeno una primaria e una secondaria";
		} else if (k === "punti") {
			if (typeof v !== "object" || v === null || Array.isArray(v)) return "punti: una tabella di punti";
			for (const [p, n] of Object.entries(v)) {
				if (!(p in dati.punti)) return `punti: punto sconosciuto ${p}`;
				if (typeof n !== "number" || !Number.isFinite(n) || n < -1000 || n > 1000) return `punti: ${p} da -1000 a 1000`;
			}
		} else return `regola sconosciuta: ${k}`;
	}
	return "";
}

function validaModello(m, dati) {
	if (!m || typeof m !== "object") return "non è un modello";
	if (!ID.test(m.id || "")) return "id: lettere minuscole, cifre e _";
	if (!(m.tipo in TIPI)) return "tipo: mod, torneo, sfida o xp";
	if (typeof m.nome !== "string" || !m.nome.trim()) return "manca il nome";
	if (m.nome.length > 60 || (m.riga || "").length > 140) return "nome o riga troppo lunghi";
	if (m.tipo === "mod") {
		if (!(m.modo in dati.modi)) return "modo: 1v1, 2v2 o ffa";
	} else if (!((m.coda || "2v2") in dati.modi)) return "coda: 1v1, 2v2 o ffa";
	if (m.regole !== undefined) {
		const e = validaRegole(m.regole, m.tipo !== "mod", dati);
		if (e) return e;
	}
	if (m.premi !== undefined) {
		if (!Array.isArray(m.premi) || m.premi.length > 8) return "premi: al massimo 8";
		for (const p of m.premi) if (!p || typeof p.testo !== "string" || !p.testo.trim()) return "premi: ogni premio vuole il testo";
	}
	return "";
}

// La finestra di un programmato: inizio, durata, i giorni in cui ricomincia
function finestre(e) {
	const da = minuti(e.da), durata = minuti(e.a) - da;
	const giorni = (e.giorni || []).length ? [...e.giorni].sort((x, y) => x - y) : [giornoSettimana(da)];
	return { da, durata, giorni };
}

function validaEvento(e, modelli, dati) {
	if (!e || typeof e !== "object") return "non è un evento";
	if (!ID.test(e.id || "")) return "id: lettere minuscole, cifre e _, al massimo 28";
	if (e.id in dati.modi) return `id: "${e.id}" è già una coda normale`;
	if (!modelli.has(e.modello)) return "il modello non c'è più";
	if (isNaN(minuti(e.da))) return "inizio: una data vera, AAAA-MM-GG HH:MM";
	if (isNaN(minuti(e.a))) return "fine: una data vera, AAAA-MM-GG HH:MM";
	if (minuti(e.a) <= minuti(e.da)) return "la fine viene prima dell'inizio";
	if (!intero(e.ogni ?? 0, 0, 52)) return "ogni: settimane da 0 a 52";
	if (e.fino && !(DATA.test(e.fino) && !isNaN(minuti(e.fino + " 00:00")))) return "fino a: una data vera";
	const g = e.giorni || [];
	if (!Array.isArray(g) || g.some((d) => !intero(d, 0, 6)) || new Set(g).size !== g.length) return "giorni: da lunedì a domenica, una volta";
	if (g.length && !e.ogni) return "i giorni vogliono una ripetizione";
	if (e.ogni) {
		// la volta dopo (anche in un altro giorno) non comincia prima che finisca questa
		const { durata, giorni } = finestre(e);
		let passo = MINUTI_SETTIMANA * e.ogni - (giorni[giorni.length - 1] - giorni[0]) * 1440;
		for (let i = 1; i < giorni.length; i++) passo = Math.min(passo, (giorni[i] - giorni[i - 1]) * 1440);
		if (durata > passo) return "dura più del tempo fino alla volta dopo: si accavallerebbe";
	}
	return "";
}

// Tutti i problemi dello stato: [{ dove, testo }], vuoto = si può pubblicare
export function valida(stato, dati) {
	const out = [];
	if (!stato || !Array.isArray(stato.modelli) || !Array.isArray(stato.eventi)) return [{ dove: "", testo: "stato rotto" }];
	if (stato.modelli.length > 200 || stato.eventi.length > 200) out.push({ dove: "", testo: "troppi modelli o eventi (200)" });
	const modelli = new Map();
	for (const m of stato.modelli) {
		const e = validaModello(m, dati);
		if (e) out.push({ dove: `modello ${m?.nome || m?.id || "?"}`, testo: e });
		else if (modelli.has(m.id)) out.push({ dove: `modello ${m.nome}`, testo: "id ripetuto" });
		modelli.set(m?.id, m);
	}
	const visti = new Set();
	for (const e of stato.eventi) {
		const nome = modelli.get(e?.modello)?.nome || e?.id || "?";
		const err = validaEvento(e, modelli, dati);
		if (err) { out.push({ dove: `evento ${nome}`, testo: err }); continue; }
		for (const f of nelFile(e, modelli.get(e.modello))) {
			if (visti.has(f.id)) out.push({ dove: `evento ${nome}`, testo: `id ripetuto: ${f.id}` });
			visti.add(f.id);
		}
	}
	return out;
}

// Un programmato come lo vuole il server: uno per ogni giorno scelto
function nelFile(e, m) {
	const base = { tipo: m.tipo, nome: m.nome };
	if (m.riga) base.riga = m.riga;
	if (m.tipo === "mod") base.modo = m.modo;
	else if (m.coda && m.coda !== "2v2") base.coda = m.coda;
	if (m.regole && Object.keys(m.regole).length) base.regole = m.regole;
	if (m.premi && m.premi.length) base.premi = m.premi;
	const { da, durata, giorni } = finestre(e);
	const dove = (id, inizio) => {
		const f = { id, ...base, da: scrivi(inizio), a: scrivi(inizio + durata) };
		if (e.ogni) f.ogni = e.ogni;
		if (e.ogni && e.fino) f.fino = e.fino;
		// da quale programmato viene, per la pagina: non enumerabile, quindi
		// non finisce nel JSON del server (che rifiuta i campi che non conosce)
		Object.defineProperty(f, "programmato", { value: e.id });
		return f;
	};
	if (!(e.giorni || []).length) return [dove(e.id, da)];
	// ogni giorno scelto: la prima volta in quel giorno da "da" in poi
	const g0 = giornoSettimana(da);
	return giorni.map((g) => dove(`${e.id}_${GIORNI[g]}`, da + ((g - g0 + 7) % 7) * 1440));
}

// Il file del server (server/events.go): { eventi: [...] }
export function file(stato) {
	const modelli = new Map(stato.modelli.map((m) => [m.id, m]));
	return { eventi: stato.eventi.flatMap((e) => nelFile(e, modelli.get(e.modello))) };
}

// Le volte degli eventi del file che toccano [da, a) (minuti), come
// Occurrences() del server: { id, evento, programmato, tipo, nome, da, a, propria }
export function volte(f, da, a) {
	const out = [];
	for (const e of f.eventi) {
		const inizio = minuti(e.da), durata = minuti(e.a) - inizio;
		const fino = e.fino ? minuti(e.fino + " 00:00") + 1440 : Infinity;
		const passo = (e.ogni || 0) * MINUTI_SETTIMANA;
		let k = passo && da > inizio + durata ? Math.max(0, Math.floor((da - inizio - durata) / passo) - 1) : 0;
		for (; ; k++) {
			const s = inizio + k * passo;
			if ((k > 0 && !passo) || s >= fino || s >= a) break;
			if (s + durata <= da) continue;
			out.push({
				id: `${e.id}-${scrivi(s).slice(0, 10).replaceAll("-", "")}`, evento: e.id,
				programmato: e.programmato ?? e.id,
				tipo: e.tipo, nome: e.nome, da: s, a: s + durata, propria: e.tipo === "mod",
			});
		}
	}
	return out.sort((x, y) => x.da - y.da || (x.id < y.id ? -1 : 1));
}

// Due eventi con la coda loro nello stesso momento dividono i giocatori:
// il pannello lo dice (Sergio, 31 ottobre: permessi, ma segnalati)
export function accavallati(vv) {
	const proprie = vv.filter((v) => v.propria), out = [];
	for (let i = 0; i < proprie.length; i++) {
		for (let j = i + 1; j < proprie.length; j++) {
			const x = proprie[i], y = proprie[j];
			if (x.da < y.a && y.da < x.a) out.push([x, y]);
		}
	}
	return out;
}
