# Pannello degli eventi

La pagina dove Sergio programma gli eventi del gioco: **modelli** (cosa cambia,
dove si gioca, premi, tetto ai livelli) messi in **calendario** con le
**ripetizioni** (una volta, ogni settimana, settimane alterne, ogni N
settimane, in più giorni della settimana, fino a una data o per sempre). Il
server scarica il calendario da qui e il pannello mostra quale versione ha
preso o perché l'ha rifiutata. È il passo 3 degli eventi (decisioni in
[docs/decisioni/progressione.md](../../docs/decisioni/progressione.md), server
in [docs/server.md](../../docs/server.md#eventi)).

- `pagina/index.html`: la pagina (niente build, niente librerie).
- `pagina/calendario.js`: controlli, file del server, ripetizioni e accavallamenti; lo usano pagina e Worker.
- `pagina/dati.json`: armi, punti, code e limiti presi dalla simulazione. Si rifà con
  `luajit strumenti/eventi/dati.lua` quando cambiano; `go test ./server/` (TestPannelloDati) fallisce se è indietro.
- `worker.js`: il Worker (API con la chiave, `/eventi.json` per il server), il calendario in KV.
- `prova.mjs`: `node strumenti/eventi/prova.mjs` fa i controlli; `node strumenti/eventi/prova.mjs 8787`
  apre il pannello su http://localhost:8787 (chiave `prova`) con un KV finto in memoria.

## Metterlo su Cloudflare (una volta)

1. Dashboard di Cloudflare → **Workers & Pages** → **Create** → **Import a repository** →
   `Sorbolik/MegaBlast`. Nome **megablast-eventi**, ramo `main`, *Path* `strumenti/eventi`,
   *Build command* vuoto, *Deploy command* `npx wrangler deploy`.
2. Al primo deploy wrangler crea da solo lo spazio KV del binding `EVENTI` (nessun id da copiare).
3. Nel Worker → **Settings** → **Variables and Secrets** → aggiungi il segreto
   **PANNELLO_CHIAVE** (una frase lunga a caso: è la password del pannello).
4. Apri `https://megablast-eventi.<tuo-sottodominio>.workers.dev`, scrivi la chiave, fai i modelli e pubblica.
5. Sul PC: `go run ./server -eventi https://megablast-eventi.<tuo-sottodominio>.workers.dev/eventi.json`.

Da lì ogni push su `main` lo ricostruisce, come l'editor delle animazioni.
Un dominio tuo si aggiunge da **Settings → Domains & Routes**.

## Come funziona

- La pagina tiene le modifiche nel browser (anche se la ricarichi) finché non premi **Pubblica**;
  non si può pubblicare finché ci sono problemi (la barra rossa dice quali).
- Il Worker ricontrolla tutto con lo stesso `calendario.js`, salva la versione nuova e la tiene
  fra le **Versioni** (ultime 30, per 90 giorni) da cui si torna indietro.
  Se nel frattempo un'altra scheda ha pubblicato, chiede se sovrascrivere.
- Il server chiede `/eventi.json` ogni 30 secondi (con l'ETag: se non è cambiato non scarica niente)
  e nella domanda dice quale versione ha e, se l'ha rifiutata, perché. Un calendario rifiutato
  non sostituisce quello buono, come col file.
- Chi sbaglia la chiave più di 10 volte in un minuto aspetta (rate limit di Cloudflare, gratis).
- `/eventi.json` è senza chiave: dice solo i prossimi eventi, che il gioco mostra comunque.
- Un programmato con più giorni diventa nel file un evento per giorno (`tutti_sab`, `tutti_dom`).
- KV gratis: 100.000 letture e 1.000 scritture al giorno. Il server ne usa ~6.000 letture;
  "server visto" si riscrive al massimo ogni 10 minuti.
