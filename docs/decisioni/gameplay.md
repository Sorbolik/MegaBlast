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
| 23 ott | Vita dei robot 150 (×1,5, Claude; da alzare ancora secondo Sergio). Turno 25 s. Il 29 ott la vita scende a 100 (vedi sotto). | PR #31 |
| 24 ott | **Respawn 1,5 s dopo la morte nello stesso turno**, vita piena, punto libero a caso; chi muore nel proprio turno continua. (Sostituisce il respawn a fine turno del 23 ott.) | PR #36 |
| 24 ott | **Nucleo rimosso** ("non pesava sulle scelte"): i secondi risparmiati al primo attacco diventano **globi di teletrasporto** (1 ogni 10 s, senza tetto; Claude: +2 entro 5 s, +1 entro 15 s); si parte con 2; al primo turno un solo lancio. Rampino una volta per turno, paracadute una volta per partita, scudo libero. | PR #39 |
| 24 ott | Paracadute: un tocco in aria lo apre, un altro lo chiude; discesa lenta, niente danno da caduta, +15% (poi +50%, PR #47) di controllo orizzontale. Scudo solo dalle casse: assorbe 60 e dimezza le spinte fino al proprio turno dopo. | PR #36, #47 |
| 24 ott | **Punti di ancoraggio rimossi**, al loro posto **cerchi di cura** che compaiono durante la partita: chi ha i piedi dentro a fine turno (di chiunque) riprende vita, poi il cerchio sparisce. Valori (Claude): ogni 2 turni, max 2, +40, raggio 26. | PR #36 |
| 24 ott | Effetti di stato: Schegge rallentano, Pugno incrina (+25% danno), bruciatura solo col set Fornace; durano fino alla fine del prossimo turno di chi li subisce; scritta che sale, icona coi turni restanti; lo scudo li ferma. | PR #31, #36 |
| 24 ott | **Draft** prima della partita: due ventagli di 3 (primarie delle casse, secondarie), uguali per tutti; 15 s; compagni senza doppioni ma con scambio; nel tutti contro tutti i doppioni vanno bene; chi non sceglie prende la prima libera. Online lo gira la stanza del server; sullo stesso telefono si sceglie a turno. | PR #31, #34, #38 |
| 24 ott | Modalità **Torneo**: 1v1 con statistiche normalizzate (albero e set non contano). | PR #34 |
| 26 ott | Trampolino largo 36 px: tutto ci rimbalza (robot, proiettili, globi, casse), 60% a ogni rimbalzo; il missile esplode e lo distrugge. | PR #45 |
| 26 ott | **Morte da soli** nel proprio turno: l'uccisione (50, senza bonus ambientale) va al nemico che ha fatto più danno in quella vita, −50 a chi si uccide, il turno continua. | PR #46 |
| 26 ott | **Teletrasporto sempre usabile** nel turno, mai disattivato dagli attacchi (restano i limiti: globi in mano, 6 in volo, 1 al primo turno; dal 29 ott quell'1 vale solo per i globi di partenza). | PR #47 |
| 29 ott | **Il teletrasporto guadagnato nel turno si usa sempre** (Sergio: "ci sono ancora occasioni in cui non posso usare un teletrasporto guadagnato in questo turno"): al primo turno il limite di un lancio vale solo per i globi di partenza, quelli guadagnati attaccando si lanciano tutti (`game.teleports_earned`, nello stato online `te`). Gli altri casi controllati non bloccano un globo guadagnato: dopo il primo attacco restano sempre 8 s (si guadagna solo con almeno 10 s), i 6 globi in volo insieme non si raggiungono, chi muore nel suo turno rinasce dopo 1,5 s e lancia ancora. | `client/sim/game.lua`, questa PR |
| 29 ott | **Globi più facili da prendere, mai tre** (Sergio: "leggermente meno frustrante prendere 2 teletrasporti... che scalino in maniera non lineare... il primo entro quanto ora +2 secondi"): soglie dall'inizio del turno, **2 globi entro 9 s, 1 entro 17 s**, dopo niente (prima 5 e 15 s). Numeri di Claude: 17 = 15 + 2 come detto da Sergio; 9 quasi raddoppia la finestra dei due globi ma resta sotto la metà del turno, così chi li prende ha mirato davvero in fretta. Non misurati coi bot: i bot attaccano quando hanno finito di pensare, non come una persona sotto pressione; si ritoccano provando. `config.TELEPORT_SOGLIE`. | `client/sim/config.lua`, questa PR |
| 29 ott | **Baratto del secondo attacco** (Sergio): dopo il primo attacco il secondo si può cambiare con un globo del teletrasporto in più; conta come guadagnato nel turno (si lancia anche al primo turno). `fire.weapon = "swap"`, evento `swap`; il bot per ora non lo usa. | `client/sim/game.lua`, questa PR |
| 26 ott | Scala del mondo: `game.CELL` 2 → 3, mondo 1920×1080 (mappe ×1,5). | PR #44 |
| 28 ott | **Hitbox separate** nella sim: capsula per camminare + cerchio dei colpi, modificabili dall'editor (`client/sim/corpo.lua`); dimensione del disegno svincolata (`game.DISEGNO_H`). | PR #55 |
| 29 ott | **Rinascita su punti d'acciaio**, a caso tra quelli liberi a più di 300 px dai nemici e lontani dalle trappole (Sergio: "sempre su parti fisse della mappa, ma sempre randomici"). I punti si trovano da soli sulle superfici d'acciaio di ogni mappa; senza acciaio, un punto libero a caso come prima. Le posizioni d'inizio partita restano quelle della mappa (Claude). **Ordine dei turni** lasciato com'è (Sergio): chi apre deve imparare a mettersi al riparo. | PR del bot |
| 29 ott | **Punti in partita, variante A senza sbalzo né doppietta** (Sergio): danno 1 per punto vita, uccisione 50, ambientale +50, morte −20 come prima; **Corona** visibile sul primo (×1,5 e +25 a chi lo abbatte, anche se il colpo che lo uccide fa primo chi colpisce); trappola che scatta +10 a chi l'ha posata; **parata** dello scudo 0,5 per punto fermato, max 30 per scudo (lo scudo dura un ciclo di turni, fino al proprio turno dopo); **Rampino e trampolino danno l'uccisione**. Variante B "Taglie" come evento "Caccia alla taglia". Pagina: https://claude.ai/artifact/Dh7MqD37ozQCJMKUZrmb4n | PR in corso |
| 29 ott | **Si muore molto prima** (Sergio: "ci vogliono 5 turni per ammazzare qualcuno, tutto deve togliere di più in percentuale", ma niente colpi che uccidono da soli). Valori (Claude, provati con 1200 + 3×800 partite di bot): vita **100** (era 150) e danni delle armi a 5/3, cioè ogni colpo toglie 2,5 volte la parte di vita di prima: Lanciarune 25 (12,5 ai bordi), Lama 25, Tonante 38, Maglio 57, Affondo 45, Pugno 47, Cecchino 50, Schegge 11, Uovo 80 al centro (non 95: sotto la vita intera) e 25 ai bordi, trappola 13, bruciatura 17, caduta fino a 75. Scudo 40, cure 27, vita di pezzi e albero a 2/3: la stessa parte di vita di prima. Nel 1v1 una vita dura 2 turni nemici (erano 4), in uno solo il 14% delle volte; morti ogni 10 turni da 2,0 a 3,9. **Punti staccati dai punti vita**: il danno vale per la percentuale di vita tolta (una vita intera = 100 punti, anche a chi ha più vita dai pezzi; la vita data da una missione non conta); con la vita a 100 resta "danno = punti". Le uccisioni passano dal 27% al 37% dei punti. Missioni ritarate col collaudo: Fuori portata 55 e il Fabbro 240 durano come prima, Due mani 46 e Corona 50 in proporzione; Primo sangue e Il codardo ora finiscono prima, seconda stella da 5 a 3 turni. Da guardare: nel 1v1 chi apre vince il 27% tra i bot (era 36%). | #79 |
| 30 ott | **Scelta delle armi rifatta** (Sergio): prima la primaria, poi la secondaria; le scelte degli altri non si vedono (il server manda a ognuno solo le sue) e i doppioni vanno bene anche fra compagni; niente più scambio col compagno; niente fila degli attrezzi: il Rampino ce l'hanno tutti, il Bastione è da ripensare (tolto dal gioco). **La prima scelta è alla Battaglia della Forgia** (fine del I girone), con le sole armi già viste (casse trovate e armi date dalle missioni finite); il tutorial non ha scelta (Sergio: le armi nuove si trovano nelle casse). | questa PR |
| 30 ott | **Il tempo della partita si ferma fra un turno e l'altro** (Sergio): finito il tempo del turno si aspetta ancora che colpi, globi e robot si fermino, ma i 5 minuti non scendono finché non comincia il turno dopo. | questa PR |

## Scartate

- Danni ×2 (una vita dura 3 turni nemici nel 1v1: ancora lenta) e ×3 (il 23% delle vite nel 1v1 finisce in un turno solo: troppo vicino al colpo che uccide), 29 ott, Claude. Alzare solo le armi lasciando la vita a 150: stesso effetto, ma i numeri del danno non sono più percentuali e i punti non sono più "danno = punti". Togliere del tutto i punti del danno (solo uccisioni): già scartato nella proposta dei punti, toglie il premio alla mira.
- **Punti di sbalzo** per le primarie (29 ott, Sergio): rischiano di rendere le uccisioni ambientali ancora più forti.
- **Doppietta** (+10 se primaria e secondaria colpiscono lo stesso nemico, 29 ott, Sergio): renderebbe scontato attaccare lo stesso nemico con due colpi; le scelte del turno devono restare aperte.
- Variante C "Gettoni" (punti fissi per colpo): toglie il premio alla mira (29 ott).
- Strato "Stile" (al volo, di rimbalzo, da lontano): rinviato, al massimo come modificatori di evento (29 ott).
- Partita a soglia di punti e attrezzo "Guardia" nel turno degli altri, anche solo come prova nell'arena (29 ott, Sergio: no).
- **Rimedi all'ordine dei turni** nel 1v1 (chi apre vince il 37% tra i bot): bonus a chi apre, giro finale, serpente, rotazione (29 ott, Sergio: no, l'ordine resta com'è).
- Fonti di punti scartate nella proposta (29 ott): sopravvivenza, casse raccolte, tempo risparmiato, precisione, danno subito, solo uccisioni, serie di uccisioni, terreno distrutto, punti da spendere, assist nel 2v2.

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

- Pesi degli oggetti nelle casse (trappola, scudo, trampolino sembravano rari):
  proposto di alzarli, nessuna decisione (24 ott).
- Durata del turno: 25 s, "forse si accorcia dopo" (23 ott).
