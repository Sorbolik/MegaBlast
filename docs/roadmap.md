# Roadmap di MegaBlast

Fissata da Sergio il 29 ottobre 2026 a partire dalla proposta
[Roadmap MegaBlast](https://claude.ai/artifact/VcD7avPDbXkcmFwwSNjAHT) (20 aree
con varianti, costi e opzioni scartate). Questo file è la versione "nella
pietra": ogni thread la consulta prima di proporre lavoro nuovo, e le modifiche
passano da Sergio.

## Principi

- **Più leggero vince**: un eseguibile Go, SQLite, zero servizi esterni finché
  non servono davvero. Nessun SDK esterno nel client.
- **Fluido su telefoni economici**: ogni dipendenza va giustificata.
- **Solo quello che serve**: niente schermate "In arrivo" nel codice.
- **Niente pay-to-win**: il negozio vende estetica; tutto il resto si guadagna
  giocando, comprare accelera soltanto.
- **Dati, non codice**: eventi, missioni, premi e testi stanno sul server e
  Sergio li cambia dal suo pannello, senza una nuova build. Le regole della
  simulazione invece richiedono sempre una build (client e server identici).
- **Una partita vera prima di tutto**.

## Decisioni per area

| # | Area | Decisione |
|---|---|---|
| 1 | Account | Ospite con codice di recupero (A); accesso Google e Apple (B) quando si pubblica su iOS. Progressione sul server da subito. |
| 2 | Server | Un VPS europeo (~5 €/mese), SQLite, Litestream per il backup continuo, Caddy per il TLS. Il server serve anche la build web e il pannello. Secondo nodo e PostgreSQL solo quando i numeri lo chiedono. |
| 3 | Eventi | Eventi come dati sul server, letti dal client. Tipi nell'ordine: Doppia XP, Torneo (classifica = migliori 10 risultati nella finestra, premi a fasce), Sfida, Modificatore. In più il **Torneo della community** (sotto). |
| 4 | Pannello | Pagina web servita dal server Go su `/admin`, chiave + TOTP. L'**editor delle animazioni** vi entra come micro-frontend (resta un progetto con vita propria, raggiungibile dal pannello con lo stesso accesso). |
| 5 | Tutorial | 3 passi obbligatori + prima partita guidata contro un bot + lezioni sbloccate. Deve far capire divertendo: due attacchi per turno, teletrasporti in proporzione al tempo risparmiato, trappole quando si vuole, rampino uno a turno, paracadute uno a partita. Quello che non entra nel tutorial lo insegna la **campagna**, con missioni che matematicamente non si finiscono senza usare la meccanica richiesta. |
| 6 | Bot | Bot euristico in Lua puro dentro `client/sim/` (gira su server e telefono), a livelli; riempie le code dopo 15 s, è l'avversario del tutorial e della campagna. In parallelo il **Laboratorio bot**: esperimenti di apprendimento automatico (reti neurali) con bot che si affrontano in migliaia di partite simulate, per trovare strategie rotte e bilanciare. Nel gioco resta l'euristico; i bot addestrati possono diventare livelli "assurdi" dell'Allenamento. |
| 7 | Campagna | Allenamento contro bot (livello a scelta, anche i bot addestrati) appena c'è il bot; poi campagna a missioni come dati (mappa, bot, regole, obiettivo, 3 stelle, premio) con la progressione a sblocco di meccaniche del punto 5. |
| 8 | Impostazioni | Una schermata: audio, comandi (mancino, levette, mira), schermo (limite fotogrammi, effetti ridotti), lingua, account (codice, collega, cancella), notifiche, info. Niente qualità grafica a livelli né rimappatura dei tasti. |
| 9 | Progressione | XP, livello, mastery, inventario e loadout calcolati e salvati dal server. Profilo pubblico leggero. Rating nascosto solo per il matchmaking. Niente classifica permanente: le classifiche sono quelle dei tornei e tra amici. In più la sezione **Statistiche, obiettivi e badge** (sotto). |
| 10 | Negozio | Estetica + valuta morbida guadagnata giocando + pacchetti a pagamento (IAP ufficiale Defold, ricevute verificate dal server); Pass dell'evento quando le skin si producono in meno di un giorno. In più i **tornei a iscrizione** (sotto). Niente pubblicità, niente casse a pagamento. |
| 11 | Amici | Codice amico, lista con stato, **lobby private** dove 4 amici giocano tra loro (FFA o 2v2) e **2v2 premade** in coda. Link di invito. Chat solo con emote o frasi predefinite. Più avanti i **clan e le guerre tra clan** (fase 6): stemma e nome, classifica di clan, guerre a finestra in cui i punti dei membri si sommano e il clan vincitore prende premi a fasce, come un torneo a squadre grandi. |
| 12 | Replay e spettatori | Replay delle ultime 10 partite dal profilo (seed + input). **Spettatore dal vivo senza ritardo**: l'amico vede quello che vedi tu; se vogliono lo streammano. |
| 13 | Notifiche | Posta in gioco + notifiche locali programmate dal calendario. Push vere solo più avanti, per inviti e premi. |
| 14 | Anti-cheat | Solo difese sul server: progressione calcolata dal server, partite offline verificate rigiocando gli input, limiti di velocità, ricevute verificate, versione minima, ban dal pannello. Nessun SDK di protezione. Ogni thread sviluppa già con questo in mente. |
| 15 | Telemetria | Eventi nostri sul server, crash dal modulo `crash` di Defold. Una **interfaccia dei dati** a sé (giocatori attivi, nuovi, ritenzione 1 e 7 giorni, attesa in coda, partite, vittorie per arma, crash), chiarissima. |
| 16 | Lingue | Tabella di testi `t("chiave")`, italiano e inglese dall'inizio; i testi degli eventi in due lingue dal pannello. Accessibilità minima: testi ≥ 12 px, squadre distinguibili anche per forma, effetti ridotti, levette per mancini. |
| 17 | Audio | Ora effetti CC0 ritoccati (A), niente musica in partita. Sergio valuta un sound designer (C) più avanti. |
| 18 | Store | Android prima, iOS un mese dopo (IPA da Windows, caricamento da GitHub Actions macOS, niente Mac), **e anche browser** servito dal nostro server. |
| 19 | Contenuti | 6 mappe alla pubblicazione; armi nuove solo come modificatori di evento; skin = pezzi sullo **stampino**. L'editor delle animazioni avrà un connettore per modificare i pezzi di riferimento dello stampino e aggiungere o togliere pezzi a un'animazione, a un personaggio nuovo, a un'arma o a una skin d'arma. |
| 20 | Sviluppo | GitHub Actions per i test (Go, Lua, simulatore), deploy del server con uno script, ambiente di prova sulla stessa macchina. |
| 21 | Interfaccia | Tutta la UI, in partita e nei menu, con il suo carattere: minimale, tranquilla, essenziale (sotto). |

Fuori per sempre, salvo ripensamento di Sergio: chat testuale, pubblicità,
classifica permanente, backend esterni (Nakama, Firebase, Supabase), editor di
mappe nel gioco, esportazione video, store alternativi, SDK di protezione del
client.

## Le novità di Sergio

### Torneo della community

Quando il gioco avrà preso piede: un post sulla pagina ufficiale (Instagram)
chiede idee per il torneo della settimana dopo; il commento più votato diventa
il torneo. Dal pannello Sergio deve poterlo fare, e l'idea può cambiare il gioco
**solo dentro quell'evento**. Serve anche a far conoscere la pagina Instagram.

Come si può fare, dal più semplice:

1. **Manuale con Claude** (prima versione). Sergio incolla nel pannello il
   commento vincente; Claude lo traduce in un evento di tipo Modificatore
   (valori di `config.lua` sovrascritti, mappa, modalità, regole del torneo,
   premi) e Sergio lo rivede e lo programma. Il "prompt" può toccare solo la
   lista bianca dei parametri di evento: niente codice nuovo, niente effetti
   fuori dall'evento. Costo zero, nessuna API.
2. **Lettura dei commenti dal pannello**. Il pannello legge i commenti del post
   con l'API Graph di Instagram (serve un account Business o Creator e
   l'approvazione dell'app da parte di Meta) e li ordina per "mi piace"; il
   resto come in 1.
3. **Voto in gioco**. Le idee si propongono e si votano dentro l'app (schermata
   Eventi), Instagram annuncia e rilancia. Più controllo (moderazione, un voto
   per account) e il voto porta gente nel gioco invece che fuori.

Raccomandazione: partire con 1 e passare a 3 quando la community c'è; la 2 vale
solo se Instagram resta il posto dove la gente parla.

### Tornei a iscrizione

Tornei speciali con accesso gratuito la prima volta: il risultato è il
piazzamento nelle proprie 10 partite della finestra. Per riprovare serve la
moneta dura, che si compra o si guadagna negli eventi e in gioco. Il torneo
normale resta sempre gratuito.

### Statistiche, obiettivi e badge

Una sezione Statistiche nel profilo con statistiche di ogni tipo, contate dal
server a fine partita: partite, vittorie per modalità, uccisioni e uccisioni
ambientali, danni fatti e subiti per arma, colpi a segno e precisione, distanza
del colpo più lungo, teletrasporti usati e guadagnati, trappole scattate,
secondi risparmiati nei turni, cadute, cure, piazzamenti nei tornei, serie di
vittorie. Ogni statistica ha **obiettivi a soglie esponenziali** (per esempio
10, 100, 1.000, 10.000) che danno un **badge** di livello crescente, sempre più
difficile da prendere. Il badge scelto (o i tre più alti) si vede a colpo
d'occhio accanto al nome in lobby, nel draft e in partita, e nel podio. Tutto
codice-disegnato nello stile Sagoma: forma e colore del badge dicono statistica
e livello. Le statistiche si contano dalla fase 1 (così nulla va perso); la
schermata, gli obiettivi e i badge arrivano in fase 3 insieme all'inventario.
Gli obiettivi sono dati sul server: Sergio può aggiungerne dal pannello.

### Interfaccia: tranquilla ed essenziale

Tutta l'interfaccia del gioco, in partita e nei menu, ha un carattere suo: il
minimalismo dello stile Sagoma (`client/ui/ui.lua`, forme disegnate in codice,
un solo font, i colori solo in `ui.C`, niente asset dipinti per la UI). Regole
che valgono per ogni schermata nuova:

- **Niente popup da cliccare**: nessuna finestra che interrompe, nessun "ok"
  da premere per andare avanti. Un premio o un avviso arriva nella posta in
  gioco o come riga discreta che scompare da sola; il podio e le ricompense
  degli eventi sono schermate, non popup.
- **Niente notifiche invadenti**: nessun badge rosso che lampeggia, nessun
  conteggio sulle voci del menu, niente notifiche di sistema per marketing.
  Un solo punto luminoso sulla posta quando c'è qualcosa di nuovo.
- **Una cosa per schermata**: ogni schermata ha un compito e lo mostra senza
  scorrere, con una gerarchia chiara; le voci che non servono ancora non
  esistono.
- **In partita solo quello che serve al turno**: armi, teletrasporti, timer e
  vita; effetti di stato come segni sul robot e scritte che salgono, mai
  pannelli. Suggerimenti solo nelle partite contro bot.
- **Transizioni brevi** (sotto i 200 ms) e mai bloccanti; effetti ridotti
  disponibili nelle impostazioni.
- **Ogni schermata nuova passa dal simulatore** (foto nel riepilogo) e da
  Sergio prima del merge, come per il resto del client.

Le schermate da fare, nell'ordine delle fasi: draft online (0), profilo e
impostazioni (1), Eventi, ricompensa, Statistiche con badge, posta (3), store e
negozio (4), campagna, amici e lobby private, spettatore (2 e 5).

### Laboratorio bot

Fuori dal gioco: migliaia di partite simulate tra bot con semi diversi, prima
euristici e poi addestrati (reti neurali, apprendimento per rinforzo), per
trovare strategie rotte e misurare armi, oggetti e mappe. È un caso di studio di
Sergio; i risultati entrano nel bilanciamento e, se buoni, come livelli estremi
dell'Allenamento.

## Fasi

In ogni fase le schermate nuove seguono le regole dell'area 21.

Ogni fase ha un criterio d'uscita verificabile. Niente di una fase successiva
entra nel codice prima che la precedente sia chiusa, salvo preparazioni a costo
zero. Lavoro: S 1–2 giorni, M 3–5, L 1–2 settimane, XL più settimane.

### 0. Chiudere la partita (in corso)

Fatto dal 26 ottobre: batch di merge, diavoletto vettoriale, editor delle
animazioni e stampino, skin armi, mappa Crogiolo con scelta casuale. Resta:
schermata del draft online nel client, vita dei robot e bilanciamento, audio di
base, tutorial raggiungibile dalla home, mappe 4–6.
**Uscita**: 4 telefoni sullo stesso Wi-Fi giocano 1v1, 2v2 e FFA fino al podio
senza bug e senza scatti; Sergio approva l'aspetto. Lavoro L, 0 €.

### 1. Online vero

VPS, dominio, TLS, SQLite, Litestream, deploy a script; account ospite;
progressione sul server con migrazione del salvataggio locale; versione minima
dal server; telemetria e crash con la prima versione dell'interfaccia dei dati;
impostazioni account e info; testi IT/EN; build web servita dal server;
conteggio delle statistiche a fine partita.
**Uscita**: due telefoni su reti mobili diverse giocano; chiudendo e riaprendo
l'app il livello è lo stesso; l'interfaccia dei dati mostra attivi e crash.
Lavoro L, 5–8 €/mese + dominio.

### 2. Primi minuti e code piene

Bot euristico a livelli (thread già aperto); tutorial corto + partita guidata +
lezioni; riempimento delle code con bot; Allenamento; lobby private tra amici e
2v2 premade (anticipate qui: servono anche per provare il gioco); impostazioni
comandi, schermo, audio; rating nascosto; replay delle ultime partite.
**Uscita**: 5 persone nuove giocano 3 partite senza spiegazioni; nessuna attesa
in coda sopra 30 s; tutorial completato da più dell'80%. Lavoro XL, 0 €.

In parallelo da qui: **Laboratorio bot** (non blocca le fasi).

### 3. Eventi e pannello

Modello eventi, schermata Eventi, Doppia XP; pannello (calendario, eventi,
premi, messaggi, stato, editor delle animazioni come micro-frontend); Torneo con
classifica e fasce di premi; inventario e schermata ricompensa; Sfide e
Modificatori; posta in gioco e notifiche locali; premi codice-disegnati
(cornici, titoli, scie); sezione Statistiche con obiettivi e badge visibili in
lobby, draft, partita e podio; Torneo della community in versione manuale.
**Uscita**: un torneo di prova di una settimana tra amici, programmato dal
pannello, si chiude e consegna i premi senza che nessuno tocchi il server.
Lavoro XL, 0 €.

### 4. Negli store e nel browser

Privacy, termini, età, schermate dello store; keystore di rilascio, account
Apple, flusso macOS; accesso Google e Apple; test interno Android e TestFlight,
poi pubblico; build browser pubblica; negozio con sola valuta morbida; 6 mappe.
**Uscita**: app pubblica su entrambi gli store e nel browser; ritenzione a 7
giorni misurata; crash sotto l'1% delle sessioni. Lavoro L, 25 $ + 99 $/anno.

### 5. Vivere di eventi

Acquisti reali, ricevute verificate, vetrina a rotazione; tornei a iscrizione
con moneta dura; campagna a missioni con stelle e sblocco di meccaniche;
spettatore dal vivo nelle lobby private; link di invito; ricetta rapida per le
skin sullo stampino e prime skin; Torneo della community con voto in gioco.
**Uscita**: tre eventi diversi in un mese senza nuova build; primo mese con
incassi che coprono il server. Lavoro XL.

### 6. Crescere

Dai numeri dell'interfaccia dei dati: Pass dell'evento, push per inviti e premi,
tornei a tabellone, clan e guerre tra clan, secondo nodo o regione, altre
lingue, sound designer.

## Come si aggiorna

Chi cambia una decisione la segna qui con la data e chi l'ha presa; chi propone
una cosa nuova la mette prima nella fase giusta. La pagina della proposta resta
come storia delle varianti scartate.
