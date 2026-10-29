// L'editor delle animazioni su Cloudflare (Worker "megablast", wrangler.jsonc):
// la pagina è in dist/ (costruisci.sh); POST /api/manda { file, lua } con
// l'intestazione X-Chiave (= EDITOR_CHIAVE) è "Manda a Claude": scrive il file
// nel ramo editor-ultima di GitHub, da dove Claude lo prende. Una richiesta degli
// strumenti ({ file: "richiesta", nome, lua: il testo, immagine: PNG in base64})
// va in richieste/<nome>.json e richieste/<nome>.png.
// Variabili cifrate del Worker: EDITOR_CHIAVE e GITHUB_TOKEN (token
// fine-grained con Contents in scrittura solo su Sorbolik/MegaBlast).
const REPO = "Sorbolik/MegaBlast";
const RAMO = "editor-ultima";
const FILE = {
	animazioni: "client/battaglia/animazioni.lua",
	corpo: "client/sim/corpo.lua",
	perni: "client/battaglia/perni.lua",
	impugnature: "client/battaglia/impugnature.lua",
	ritocchi: "strumenti/stampino/ritocchi.json",
};


function base64(testo) {
	const b = new TextEncoder().encode(testo);
	let s = "";
	for (let i = 0; i < b.length; i += 0x8000) s += String.fromCharCode(...b.subarray(i, i + 0x8000));
	return btoa(s);
}

export default {
	async fetch(request, env) {
		if (new URL(request.url).pathname !== "/api/manda") return env.ASSETS.fetch(request);
		// la pagina chiede se c'è: allora mostra il pulsante
		if (request.method === "GET") return new Response("ok");
		if (request.method !== "POST") return new Response("no", { status: 405 });
		return manda(request, env);
	},
};

async function manda(request, env) {
	if (!env.EDITOR_CHIAVE || request.headers.get("X-Chiave") !== env.EDITOR_CHIAVE) {
		return new Response("chiave sbagliata", { status: 403 });
	}
	let file, lua, nome, immagine;
	try { ({ file, lua, nome, immagine } = await request.json()); } catch (e) { return new Response("richiesta rotta", { status: 400 }); }
	// i file da scrivere: percorso -> contenuto in base64
	const scritti = {};
	if (file === "richiesta") {
		if (!/^[a-z][a-z0-9_]{0,39}$/.test(nome || "") || typeof immagine !== "string" || immagine.length > 12000000
			|| !/^[A-Za-z0-9+/=]+$/.test(immagine) || typeof lua !== "string" || lua.length > 100000) return new Response("richiesta sbagliata", { status: 400 });
		scritti[`richieste/${nome}.json`] = base64(lua);
		scritti[`richieste/${nome}.png`] = immagine;
	} else {
		if (!FILE[file] || typeof lua !== "string" || lua.length > 2000000) return new Response("file sconosciuto", { status: 400 });
		scritti[FILE[file]] = base64(lua);
	}
	const api = (p, init = {}) => fetch(`https://api.github.com/repos/${REPO}${p}`, {
		...init,
		headers: {
			Authorization: `Bearer ${env.GITHUB_TOKEN}`,
			Accept: "application/vnd.github+json",
			"User-Agent": "megablast-editor",
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
			body: JSON.stringify({ message: `Editor: ${file} di Sergio`, content: contenuto, branch: RAMO, sha }),
		});
		if (!r.ok) return new Response("GitHub: " + await r.text(), { status: 502 });
	}
	return new Response("ok");
}
