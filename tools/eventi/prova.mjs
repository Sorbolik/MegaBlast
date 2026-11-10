// Prova del pannello degli eventi senza Cloudflare: il Worker con un KV finto.
//
//   node tools/eventi/prova.mjs            i controlli (calendario, Worker)
//   node tools/eventi/prova.mjs 8787       il pannello su http://localhost:8787
//                                              (chiave "prova"), per provarlo nel browser o col server:
//                                              go run ./server -eventi http://localhost:8787/eventi.json
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import worker from "./worker.js";
import dati from "./pagina/dati.json" with { type: "json" };
import { valida, file, volte, accavallati, minuti } from "./pagina/calendario.js";

const PAGINA = new URL("./pagina/", import.meta.url).pathname;
const TIPO = { ".html": "text/html", ".js": "text/javascript", ".json": "application/json" };

function kv() {
	const m = new Map();
	return {
		m,
		async get(k, tipo) { const v = m.get(k)?.v; return v === undefined ? null : tipo === "json" ? JSON.parse(v) : v; },
		async getWithMetadata(k) { const x = m.get(k); return { value: x?.v ?? null, metadata: x?.meta ?? null }; },
		async put(k, v, o = {}) { m.set(k, { v, meta: o.metadata }); },
	};
}
const env = {
	PANNELLO_CHIAVE: "prova", EVENTI: kv(),
	ASSETS: { async fetch(r) {
		let p = new URL(r.url).pathname;
		if (p === "/") p = "/index.html";
		try { return new Response(await readFile(join(PAGINA, p)), { headers: { "Content-Type": TIPO[extname(p)] || "application/octet-stream" } }); }
		catch { return new Response("non c'è", { status: 404 }); }
	} },
};

if (process.argv[2]) {
	const porta = +process.argv[2];
	createServer(async (req, res) => {
		const corpo = req.method === "GET" ? undefined : await new Promise((ok) => { let b = ""; req.on("data", (c) => (b += c)); req.on("end", () => ok(b)); });
		const r = await worker.fetch(new Request(`http://localhost:${porta}${req.url}`, { method: req.method, headers: req.headers, body: corpo }), env);
		res.writeHead(r.status, Object.fromEntries(r.headers));
		res.end(Buffer.from(await r.arrayBuffer()));
	}).listen(porta, () => console.log(`pannello su http://localhost:${porta} (chiave "prova")`));
} else {
	let falliti = 0;
	const check = (ok, nome) => { console.log((ok ? "ok   " : "NO   ") + nome); if (!ok) falliti++; };
	const chiama = (p, init = {}) => worker.fetch(new Request("http://x" + p, { ...init, headers: { "X-Chiave": "prova", ...(init.headers || {}) } }), env);

	const modelli = [
		{ id: "maglio", nome: "2V2 SOLO MAGLIO", tipo: "mod", modo: "2v2", regole: { armi: ["punch", "mallet"], casse: 2 }, premi: [{ testo: "Badge Maglio", chi: "primi 10%" }] },
		{ id: "torneo", nome: "TORNEO 2V2", tipo: "torneo", regole: { tetto: 15 } },
		{ id: "ffa", nome: "TUTTI CONTRO TUTTI", tipo: "mod", modo: "ffa" },
	];
	const eventi = [
		{ id: "maglio", modello: "maglio", da: "2026-11-02 10:00", a: "2026-11-04 23:59", ogni: 2 },
		{ id: "torneo", modello: "torneo", da: "2026-11-06 18:00", a: "2026-11-08 22:00", ogni: 1, fino: "2026-11-13" },
		{ id: "tutti", modello: "ffa", da: "2026-11-07 18:00", a: "2026-11-07 22:00", ogni: 1, giorni: [5, 6] },
	];
	const S = { modelli, eventi };
	check(valida(S, dati).length === 0, "un calendario giusto passa");
	const f = file(S);
	check(f.eventi.map((e) => e.id).join(" ") === "maglio torneo tutti_sab tutti_dom", "i giorni scelti diventano un evento per giorno");
	check(f.eventi[3].da === "2026-11-08 18:00" && f.eventi[3].a === "2026-11-08 22:00" && !("programmato" in JSON.parse(JSON.stringify(f)).eventi[3]),
		"domenica stessa finestra, e niente campi in più nel file");
	check(f.eventi[1].regole.tetto === 15 && !f.eventi[1].modo && f.eventi[0].modo === "2v2", "il Torneo sta sulla coda normale col tetto");
	const vv = volte(f, minuti("2026-11-03 12:00"), minuti("2026-11-17 12:00"));
	check(vv.map((v) => v.id).join(" ") === "maglio-20261102 torneo-20261106 tutti_sab-20261107 tutti_dom-20261108 torneo-20261113 tutti_sab-20261114 tutti_dom-20261115 maglio-20261116",
		"le volte come le espande il server");
	check(vv.find((v) => v.id === "tutti_dom-20261108").programmato === "tutti", "ogni volta sa da quale programmato viene");
	check(accavallati(volte(file({ modelli, eventi: [...eventi, { id: "m2", modello: "maglio", da: "2026-11-07 20:00", a: "2026-11-07 23:00" }] }),
		minuti("2026-11-07 00:00"), minuti("2026-11-08 00:00"))).length === 1, "due code proprie insieme si segnalano");
	const sbagliati = {
		"arma sconosciuta": { modelli: [{ ...modelli[0], regole: { armi: ["laser", "mallet"] } }], eventi: [] },
		"regole sul torneo": { modelli: [{ ...modelli[1], regole: { casse: 2 } }], eventi: [] },
		"tetto alto": { modelli: [{ ...modelli[1], regole: { tetto: 30 } }], eventi: [] },
		"si accavalla": { modelli, eventi: [{ ...eventi[0], a: "2026-11-20 10:00" }] },
		"giorni troppo vicini": { modelli, eventi: [{ ...eventi[2], a: "2026-11-09 10:00" }] },
		"giorni senza ripetizione": { modelli, eventi: [{ ...eventi[2], ogni: 0 }] },
		"data che non c'è": { modelli, eventi: [{ ...eventi[0], da: "2026-02-30 10:00" }] },
		"id di una coda": { modelli, eventi: [{ ...eventi[0], id: "ffa" }, { ...eventi[2], id: "x" }].map((e, i) => (i ? e : { ...e, id: "2v2" })) },
		"modello che non c'è": { modelli, eventi: [{ ...eventi[0], modello: "boh" }] },
		"id ripetuto": { modelli, eventi: [eventi[0], eventi[0]] },
	};
	for (const [nome, s] of Object.entries(sbagliati)) check(valida(s, dati).length > 0, "rifiutato: " + nome);

	// il Worker
	check((await worker.fetch(new Request("http://x/api/stato"), env)).status === 403, "senza chiave no");
	let n = 0;
	const limitato = { ...env, TENTATIVI: { async limit() { return { success: ++n <= 10 }; } } };
	for (let i = 0; i < 10; i++) await worker.fetch(new Request("http://x/api/stato", { headers: { "X-Chiave": "boh" } }), limitato);
	check((await worker.fetch(new Request("http://x/api/stato", { headers: { "X-Chiave": "boh" } }), limitato)).status === 429, "troppe chiavi sbagliate: si aspetta");
	let r = await (await chiama("/api/stato")).json();
	check(r.stato.versione === 0 && r.esito === null, "all'inizio è vuoto");
	let p = await chiama("/api/stato", { method: "POST", body: JSON.stringify({ base: 0, ...sbagliati["arma sconosciuta"] }) });
	check(p.status === 400, "il Worker ricontrolla e rifiuta");
	p = await chiama("/api/stato", { method: "POST", body: JSON.stringify({ base: 0, ...S }) });
	check(p.ok && (await p.json()).versione === 1, "pubblicata la versione 1");
	p = await chiama("/api/stato", { method: "POST", body: JSON.stringify({ base: 0, ...S }) });
	check(p.status === 409, "chi pubblica su una versione vecchia non sovrascrive");
	let g = await worker.fetch(new Request("http://x/eventi.json"), env);
	const etag = g.headers.get("ETag");
	check(g.ok && etag === '"1"' && JSON.stringify(await g.json()) === JSON.stringify(f), "il server scarica il file, senza chiave");
	g = await worker.fetch(new Request("http://x/eventi.json?preso=1&errore=", { headers: { "If-None-Match": etag } }), env);
	check(g.status === 304, "304 se non è cambiato");
	g = await worker.fetch(new Request("http://x/eventi.json?preso=" + encodeURIComponent('W/"1'), { headers: { "If-None-Match": "W/" + etag } }), env);
	check(g.status === 304 && (await env.EVENTI.get("esito", "json")).versione === 1, "anche con l'ETag debole di Cloudflare (W/)");
	r = await (await chiama("/api/stato")).json();
	check(r.esito.versione === 1 && r.esito.errore === "" && r.storia.length === 1, "il pannello sa che il server l'ha presa");
	await worker.fetch(new Request("http://x/eventi.json?preso=1&errore=" + encodeURIComponent("evento \"x\": è rotto")), env);
	r = await (await chiama("/api/stato")).json();
	check(r.esito.errore === "evento \"x\": è rotto", "e se l'ha rifiutata, perché");
	const v1 = await (await chiama("/api/versione?n=1")).json();
	check(v1.eventi.length === 3, "le versioni passate si riprendono");
	console.log(falliti ? `${falliti} controlli falliti` : "tutti i controlli superati");
	process.exit(falliti ? 1 : 0);
}
