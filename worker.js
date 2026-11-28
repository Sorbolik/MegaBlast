// Il Copione su Cloudflare (Worker "megablast-copione", wrangler.jsonc): la
// pagina e la build web in dist/ (costruisci.sh; .github/workflows/copione.yml
// dopo ogni merge su main mette tutto, già costruito, nel ramo copione-pubblica,
// da cui Cloudflare lo pubblica). POST /api/manda con
// l'intestazione X-Chiave (= EDITOR_CHIAVE, la stessa dell'editor) è "Manda a Claude": scrive
// client/sim/levels.lua e copione/ultima.json (capitoli, JSON, livello aperto,
// quando) nel ramo editor-ultima di GitHub, da dove Claude li prende.
// Variabili cifrate del Worker, come nell'editor delle animazioni:
// EDITOR_CHIAVE e GITHUB_TOKEN (token fine-grained con Contents in scrittura
// solo su Sorbolik/MegaBlast).
const REPO = "Sorbolik/MegaBlast";
const RAMO = "editor-ultima";

function base64(testo) {
	const b = new TextEncoder().encode(testo);
	let s = "";
	for (let i = 0; i < b.length; i += 0x8000) s += String.fromCharCode(...b.subarray(i, i + 0x8000));
	return btoa(s);
}

export default {
	async fetch(request, env) {
		if (new URL(request.url).pathname !== "/api/manda") return env.ASSETS.fetch(request);
		// la pagina chiede se c'è: allora manda di qui e non dal database di claude.ai
		if (request.method === "GET") return new Response("ok");
		if (request.method !== "POST") return new Response("no", { status: 405 });
		return manda(request, env);
	},
};

async function manda(request, env) {
	if (!env.EDITOR_CHIAVE || request.headers.get("X-Chiave") !== env.EDITOR_CHIAVE) {
		return new Response("chiave sbagliata", { status: 403 });
	}
	let corpo;
	try { corpo = await request.json(); } catch (e) { return new Response("richiesta rotta", { status: 400 }); }
	const { lua, capitoli, json, livello, quando } = corpo || {};
	if (typeof lua !== "string" || lua.length > 3000000 || typeof json !== "string" || json.length > 3000000) {
		return new Response("copione sbagliato", { status: 400 });
	}
	const scritti = {
		"client/sim/levels.lua": base64(lua),
		"copione/ultima.json": base64(JSON.stringify({ capitoli, livello, quando, json }, null, 1)),
	};
	const api = (p, init = {}) => fetch(`https://api.github.com/repos/${REPO}${p}`, {
		...init,
		headers: {
			Authorization: `Bearer ${env.GITHUB_TOKEN}`,
			Accept: "application/vnd.github+json",
			"User-Agent": "megablast-copione",
			"Content-Type": "application/json",
		},
	});
	// il ramo, se non c'è ancora, parte da main
	let r = await api(`/git/ref/heads/${RAMO}`);
	if (r.status === 404) {
		const main = await (await api("/git/ref/heads/main")).json();
		r = await api("/git/refs", { method: "POST", body: JSON.stringify({ ref: `refs/heads/${RAMO}`, sha: main.object.sha }) });
		if (!r.ok) return new Response("GitHub: " + await r.text(), { status: 502 });
	}
	for (const [percorso, contenuto] of Object.entries(scritti)) {
		r = await api(`/contents/${percorso}?ref=${RAMO}`);
		const sha = r.ok ? (await r.json()).sha : undefined;
		r = await api(`/contents/${percorso}`, {
			method: "PUT",
			body: JSON.stringify({ message: `Copione di Sergio${livello ? " (" + livello + ")" : ""}`, content: contenuto, branch: RAMO, sha }),
		});
		if (!r.ok) return new Response("GitHub: " + await r.text(), { status: 502 });
	}
	return new Response("ok");
}
