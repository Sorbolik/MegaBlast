// "Manda a Claude" dell'editor delle animazioni pubblicato su Cloudflare Pages:
// POST /api/manda { file, lua } con l'intestazione X-Chiave (= EDITOR_CHIAVE)
// scrive il file nel ramo editor-ultima di GitHub, da dove Claude lo prende.
// Segreti del progetto Pages: EDITOR_CHIAVE e GITHUB_TOKEN (contents in
// scrittura su Sorbolik/MegaBlast), messi da .github/workflows/editor.yml.
const REPO = "Sorbolik/MegaBlast";
const RAMO = "editor-ultima";
const FILE = {
	animazioni: "client/battaglia/animazioni.lua",
	corpo: "client/sim/corpo.lua",
	perni: "client/battaglia/perni.lua",
};

// la pagina chiede se c'è: allora mostra il pulsante
export function onRequestGet() {
	return new Response("ok");
}

function base64(testo) {
	const b = new TextEncoder().encode(testo);
	let s = "";
	for (let i = 0; i < b.length; i += 0x8000) s += String.fromCharCode(...b.subarray(i, i + 0x8000));
	return btoa(s);
}

export async function onRequestPost({ request, env }) {
	if (!env.EDITOR_CHIAVE || request.headers.get("X-Chiave") !== env.EDITOR_CHIAVE) {
		return new Response("chiave sbagliata", { status: 403 });
	}
	let file, lua;
	try { ({ file, lua } = await request.json()); } catch (e) { return new Response("richiesta rotta", { status: 400 }); }
	const percorso = FILE[file];
	if (!percorso || typeof lua !== "string" || lua.length > 2000000) return new Response("file sconosciuto", { status: 400 });
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
	r = await api(`/contents/${percorso}?ref=${RAMO}`);
	const sha = r.ok ? (await r.json()).sha : undefined;
	r = await api(`/contents/${percorso}`, {
		method: "PUT",
		body: JSON.stringify({ message: `Editor: ${file} di Sergio`, content: base64(lua), branch: RAMO, sha }),
	});
	if (!r.ok) return new Response("GitHub: " + await r.text(), { status: 502 });
	return new Response("ok");
}
