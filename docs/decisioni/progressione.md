# Progressione, podio, equipaggiamento, premi

Codice: `client/sim/abilita.lua`, `equipaggiamento.lua`, `assetto.lua`,
`riconoscimenti.lua`; schermate `client/menu/profilo.lua`, `podio.lua`,
`armeria.lua`. Principi in [../game_design_competitivo.md](../game_design_competitivo.md),
futuro in [../roadmap.md](../roadmap.md) (aree 9, 10).

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 19 ott | L'equipaggiamento modifica le statistiche (velocità a terra, salto, velocità in aria). | PR #7 |
| 20 ott | **Niente pay-to-win**: in partita contano abilità e strategia; le personalizzazioni a pagamento sono solo estetiche. | docs/design.md |
| 23 ott | Equipaggiamento = **sidegrade** (più/meno in %) + **tier** solo estetici; niente ranked permanente: modalità Torneo a tempo con normalizzazione. | game_design_competitivo.md |
| 23 ott | **Albero delle abilità**: sì, piccolo, sempre rispeccabile gratis; meno punti che nodi (20 su 70), nodi misti (statistiche + risorse), divario ≤ 10% in partita normale; nel Torneo tutti al massimo. 3 loadout salvati. La differenza di livello si deve sentire ma deve essere colmabile con la strategia. | game_design_competitivo.md, PR #33 |
| 23 ott | Riconoscimenti di fine partita: sì. **Calendario di eventi** al posto delle stagioni, premi a fasce (es. top 100 skin + pezzo, 101–300 skin). Negozio: solo estetica; il resto marginale e raggiungibile giocando. | game_design_competitivo.md |
| 23 ott | Implementato: 3 rami (Mobilità, Difesa, Arsenale), 2 punti per livello, cancello di riga 3; 4 set × 4 slot (Corvo doppio salto, Fornace bruciatura, Leviatano spinta e caduta, Vuoto teletrasporto), tier da partite giocate 0/10/30; XP 120/80/60/50 per piazzamento + 25 per riconoscimento, livello n→n+1 = 100 + 25(n−1); podio 1,5 s dopo la fine (tutti valori Claude). Progresso locale dell'hot-seat al robot 1. | PR #33 |
| 23 ott | Revisione del coordinatore: niente voci "in arrivo"; nodi e bonus solo per meccaniche già in gioco; negozio, calendario eventi e valuta tolti finché non esistono account e server (erano nel commit ad29ffd). | PR #33 |
| 24 ott | Col Nucleo rimosso: nodi "Globo di riserva" (+1 teletrasporto) e "Ali di riserva" (+1 paracadute); Guscio e Passo leggero tolti; Vuoto B e Fornace +1 globo; Corvo B = 2 salti in aria; riconoscimento Tesoriere tolto. | PR #39 |
| 24 ott | Colori delle squadre solo da `ui.C.SQUADRA`, ordine Rosso, Blu, Verde, Oro. | PR #33 |
| 29 ott | Progressione **sul server** (XP, livello, mastery, inventario, loadout), rating nascosto solo per il matchmaking, profilo pubblico leggero. **Statistiche di ogni tipo** con obiettivi a soglie esponenziali e **badge** visibili accanto al nome. Negozio: estetica + valuta morbida + pacchetti; tornei a iscrizione con moneta dura; pass dell'evento più avanti. | docs/roadmap.md |
| 29 ott | **Set liberi e progressione a poco a poco** (Sergio): i pezzi si potranno mischiare (non più solo 4 set fissi, i pezzi nuovi si fanno con l'editor); all'inizio non si regala un set completo, si parte senza niente e si comprano i pezzi. Il gioco è da late game ma con progressione: il divario lo colmano matchmaking, livello fisso nei tornei e il fatto che in qualche mese si completa l'equipaggiamento; escono sempre pezzi nuovi per far girare il meta. | thread del bot |

## Scartate

- Nodi dell'albero legati al Nucleo (23 ott): superati con la rimozione del Nucleo.
- Mezzi Nuclei come sconto dell'albero: "il primo è gratis" (Claude, 23 ott).
- Classifica globale permanente con rating visibile (29 ott): contro la
  decisione del 23 ott; il rating resta nascosto.
- Pubblicità con premio, app a pagamento, casse a pagamento con contenuto
  casuale (29 ott).

## Aperte

- Nome della valuta morbida ("Scorie"? il nome viene dalla vecchia direzione
  artistica).
- Sconto del negozio e prezzi: da provare con sola valuta morbida in fase 4.
