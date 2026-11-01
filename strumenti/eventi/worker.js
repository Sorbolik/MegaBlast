// Il pannello degli eventi su Cloudflare (Worker "megablast-eventi",
// wrangler.jsonc; come si mette su: README.md). La pagina è in pagina/; il
// calendario sta in KV (binding EVENTI):
//
//   GET  /eventi.json            il file che scarica il server (server/eventi.go), senza chiave;
//                                ?preso=N&errore=… dice quale versione ha preso il server e se l'ha rifiutata
//   GET  /api/stato              (X-Chiave) modelli, eventi, versione, cosa ha detto il server, le versioni passate
//   POST /api/stato              (X-Chiave) { base, modelli, eventi }: ricontrolla tutto e pubblica
//   GET  /api/versione?n=N       (X-Chiave) una versione passata, per tornarci
//
// Variabile cifrata del Worker: PANNELLO_CHIAVE (la chiave che Sergio scrive
// nella pagina la prima volta).
import dati from "./pagina/dati.json" with { type: "json" };
import { valida, file } from "./pagina/calendario.js";

const STORIA = 30; // versioni passate che si tengono
const GIORNI_STORIA = 90;
const VISTO_OGNI = 10 * 60 * 1000; // "server visto" si riscrive al massimo ogni 10 minuti: KV gratis = 1000 scritture al giorno

const json = (v, status = 200, headers = {}) =>
	new Response(JSON.stringify(v), { status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store", ...headers } });

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		if (url.pathname === "/eventi.json" && request.method === "GET") return perIlServer(request, url, env);
		if (!url.pathname.startsWith("/api/")) return env.ASSETS.fetch(request);
		if (!env.PANNELLO_CHIAVE) return json({ errore: "Manca PANNELLO_CHIAVE nelle variabili del Worker" }, 503);
		if (request.headers.get("X-Chiave") !== env.PANNELLO_CHIAVE) return json({ errore: "Chiave sbagliata" }, 403);
		if (url.pathname === "/api/stato" && request.method === "GET") return stato(env);
		if (url.pathname === "/api/stato" && request.method === "POST") return pubblica(request, env);
		if (url.pathname === "/api/versione" && request.method === "GET") {
			const v = await env.EVENTI.get(`v:${parseInt(url.searchParams.get("n"), 10)}`, "json");
			return v ? json(v) : json({ errore: "Versione non trovata" }, 404);
		}
		return json({ errore: "Non c'è" }, 404);
	},
};

const vuoto = () => ({ versione: 0, quando: null, modelli: [], eventi: [] });

async function stato(env) {
	const [s, esito, storia] = await Promise.all([
		env.EVENTI.get("stato", "json"), env.EVENTI.get("esito", "json"), env.EVENTI.get("storia", "json"),
	]);
	return json({ stato: s || vuoto(), esito, storia: storia || [] });
}

async function pubblica(request, env) {
	let corpo;
	try { corpo = await request.json(); } catch { return json({ errore: "Richiesta rotta" }, 400); }
	const nuovo = { modelli: corpo?.modelli, eventi: corpo?.eventi };
	const problemi = valida(nuovo, dati);
	if (problemi.length) return json({ errore: "Il calendario ha dei problemi", problemi }, 400);
	const ora = (await env.EVENTI.get("stato", "json")) || vuoto();
	// due schede aperte: chi pubblica per secondo non cancella il lavoro del primo
	if (corpo.base !== ora.versione) return json({ errore: "Nel frattempo è stata pubblicata un'altra versione", stato: ora }, 409);
	const s = { versione: ora.versione + 1, quando: new Date().toISOString(), modelli: nuovo.modelli, eventi: nuovo.eventi };
	const storia = [{ versione: s.versione, quando: s.quando, eventi: s.eventi.length }, ...((await env.EVENTI.get("storia", "json")) || [])].slice(0, STORIA);
	// prima la versione e la storia, poi lo stato e per ultimo il file del server
	await env.EVENTI.put(`v:${s.versione}`, JSON.stringify(s), { expirationTtl: GIORNI_STORIA * 86400 });
	await env.EVENTI.put("storia", JSON.stringify(storia));
	await env.EVENTI.put("stato", JSON.stringify(s));
	await env.EVENTI.put("file", JSON.stringify(file(s), null, "\t"), { metadata: { versione: s.versione } });
	return json({ versione: s.versione, quando: s.quando });
}

async function perIlServer(request, url, env) {
	const { value, metadata } = await env.EVENTI.getWithMetadata("file");
	const versione = metadata?.versione ?? 0;
	const etag = `"${versione}"`;
	// il server dice cosa ha fatto con la versione che ha: si scrive solo quando cambia
	if (url.searchParams.has("preso")) {
		const esito = { versione: parseInt(url.searchParams.get("preso"), 10) || 0, errore: (url.searchParams.get("errore") || "").slice(0, 500) };
		const prima = await env.EVENTI.get("esito", "json");
		const adesso = Date.now();
		if (!prima || prima.versione !== esito.versione || prima.errore !== esito.errore || adesso - (prima.visto || 0) > VISTO_OGNI) {
			await env.EVENTI.put("esito", JSON.stringify({ ...esito, visto: adesso }));
		}
	}
	const headers = { ETag: etag, "Cache-Control": "no-store" };
	if (request.headers.get("If-None-Match") === etag) return new Response(null, { status: 304, headers });
	return new Response(value || '{"eventi": []}', { headers: { ...headers, "Content-Type": "application/json" } });
}
