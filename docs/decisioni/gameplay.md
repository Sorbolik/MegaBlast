# Gameplay: regole della partita

I numeri correnti sono in `client/sim/config.lua`; la descrizione completa
delle regole in [../design.md](../design.md); le varianti valutate in
[../game_design_competitivo.md](../game_design_competitivo.md).

## Decisioni prese

| Data | Decisione | Dove |
|---|---|---|
| 19 ott | Salto libero anche verticale con controllo in aria; robot veloci con controllo scattante; **niente vento**; qualche secondo di movimento dopo lo sparo; mappe fatte a mano, non procedurali. | PR #7 |
| 19 ott | Partite da 2 a 4 giocatori (1v1, 2v2, tutti contro tutti) che finiscono su un **podio**. | memoria |
| 20 ott | Teletrasporto "Passo d'Ombra": lancia un globo, dopo ~2 s il robot appare lì **nello stesso stato** (velocità, fendente in corso: combo colpo dietro, teletrasporto, colpo davanti). Lama di Nucleo: spadone, fendente 240° da dietro la schiena a davanti, colpisce dietro e davanti, **nessuna spinta**. | PR #12, #18–#22 |
| 20 ott | Robot solidi tra loro, spinta al 30% camminando contro. | PR #22 |
| 21 ott | Profilo fisico "blastron" di default (robot 20 px, mira che ruota tutto il fendente: mirando in basso la spada scende); comandi a due levette tipo Blastron, con lo smorzamento della mira mantenuto, "basati sul tempo, non sui frame". | PR #23 |
| 22–23 ott | Partita **semi-competitiva e tattica**: premiare chi usa meno dei 25 s; strategie scelte: uccisioni ambientali, punti del podio oltre le uccisioni, effetti di stato. Non scelte: zone della mappa, turni che si accorciano, cose da fare mentre si aspetta. | game_design_competitivo.md (PR #28) |
| 23 ott | **Due attacchi per turno** (una primaria + una secondaria, ordine libero). Dopo il primo attacco una finestra (8 s dal 24 ott, mai oltre il timer) per il secondo e per muoversi; barra gialla finché resta il secondo, blu dopo, lampeggia negli ultimi 2 s. | PR #31, #36 |
| 23 ott | Partita di **5 minuti**, vince la squadra con più punti. Punti (Claude): 1 per punto vita tolto, 50 uccisione, +50 ambientale, −20 a chi muore, ×1,5 colpendo il primo; uccisione a chi ha colpito per ultimo nei 10 s; fuoco amico fa danno ma non dà punti. Allo scadere si finisce il giro di turni ("Supplementari"). | PR #31, #36 |
| 23 ott | Vita dei robot 150 (×1,5, Claude; da alzare ancora secondo Sergio). Turno 25 s. | PR #31 |
| 24 ott | **Respawn 1,5 s dopo la morte nello stesso turno**, vita piena, punto libero a caso; chi muore nel proprio turno continua. (Sostituisce il respawn a fine turno del 23 ott.) | PR #36 |
| 24 ott | **Nucleo rimosso** ("non pesava sulle scelte"): i secondi risparmiati al primo attacco diventano **globi di teletrasporto** (1 ogni 10 s, senza tetto; Claude: +2 entro 5 s, +1 entro 15 s); si parte con 2; al primo turno un solo lancio. Rampino una volta per turno, paracadute una volta per partita, scudo libero. | PR #39 |
| 24 ott | Paracadute: un tocco in aria lo apre, un altro lo chiude; discesa lenta, niente danno da caduta, +15% (poi +50%, PR #47) di controllo orizzontale. Scudo solo dalle casse: assorbe 60 e dimezza le spinte fino al proprio turno dopo. | PR #36, #47 |
| 24 ott | **Punti di ancoraggio rimossi**, al loro posto **cerchi di cura** che compaiono durante la partita: chi ha i piedi dentro a fine turno (di chiunque) riprende vita, poi il cerchio sparisce. Valori (Claude): ogni 2 turni, max 2, +40, raggio 26. | PR #36 |
| 24 ott | Effetti di stato: Schegge rallentano, Pugno incrina (+25% danno), bruciatura solo col set Fornace; durano fino alla fine del prossimo turno di chi li subisce; scritta che sale, icona coi turni restanti; lo scudo li ferma. | PR #31, #36 |
| 24 ott | **Draft** prima della partita: due ventagli di 3 (primarie delle casse, secondarie), uguali per tutti; 15 s; compagni senza doppioni ma con scambio; nel tutti contro tutti i doppioni vanno bene; chi non sceglie prende la prima libera. Online lo gira la stanza del server; sullo stesso telefono si sceglie a turno. | PR #31, #34, #38 |
| 24 ott | Modalità **Torneo**: 1v1 con statistiche normalizzate (albero e set non contano). | PR #34 |
| 26 ott | Trampolino largo 36 px: tutto ci rimbalza (robot, proiettili, globi, casse), 60% a ogni rimbalzo; il missile esplode e lo distrugge. | PR #45 |
| 26 ott | **Morte da soli** nel proprio turno: l'uccisione (50, senza bonus ambientale) va al nemico che ha fatto più danno in quella vita, −50 a chi si uccide, il turno continua. | PR #46 |
| 26 ott | **Teletrasporto sempre usabile** nel turno, mai disattivato dagli attacchi (restano i limiti: globi in mano, 6 in volo, 1 al primo turno). | PR #47 |
| 26 ott | Scala del mondo: `game.CELL` 2 → 3, mondo 1920×1080 (mappe ×1,5). | PR #44 |
| 28 ott | **Hitbox separate** nella sim: capsula per camminare + cerchio dei colpi, modificabili dall'editor (`client/sim/corpo.lua`); dimensione del disegno svincolata (`game.DISEGNO_H`). | PR #55 |

## Scartate

- Nucleo come risorsa (23–24 ott): l'entrata superava la spesa, barra sempre
  piena, comprava movimento già gratis. Pagina di analisi:
  https://claude.ai/artifact/MkARkaLVum37MLH41grVPV
- Mezzi Nuclei, oggetti da 2 Nuclei: mai entrati.
- Fine del turno alla morte, punti a tutti i nemici, solo penalità, rilevamento
  dell'intenzione (morte da soli, 26 ott): tenute come opzioni più dure.
- Casse ogni 2 turni: provato e tolto da Sergio (24 ott), tornate ogni 3 dal 4°.
- Classifica permanente: no, i tornei a finestra sono la classifica (23 ott,
  confermato il 29 ott).
- Rimbalzo elastico sul trampolino: un missile verticale rimbalzerebbe per
  sempre e bloccherebbe il turno.

## Aperte

- Vita dei robot: Sergio ha detto di alzarla ancora (23 ott), valore da
  decidere col bilanciamento della fase 0.
- Pesi degli oggetti nelle casse (trappola, scudo, trampolino sembravano rari):
  proposto di alzarli, nessuna decisione (24 ott).
- Durata del turno: 25 s, "forse si accorcia dopo" (23 ott).
