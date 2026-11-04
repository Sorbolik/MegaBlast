# UI-002 · Proposta Stile Grafico: Sagoma Tattica & Identità dei Componenti

- **Stato:** PROPOSTA (per Sergio e Claude)
- **Data:** 2026-11-04
- **Autore:** Codex / Antigravity
- **Destinatari:** Sergio (Direttore del gioco) e Claude (Coordinatore del progetto MegaBlast)
- **Riferimenti:** [docs/decisioni/interfaccia.md](../decisioni/interfaccia.md), [docs/handoff/UI-001_analisi_interfacce_hud_user_experience.md](UI-001_analisi_interfacce_hud_user_experience.md)
- **Prototipo Figma Interattivo:** [UI-002_figma_prototype.html](UI-002_figma_prototype.html) (apribile in qualsiasi browser)
- **Generatore Asset Hi-DPI:** `strumenti/grafica/ui_nuova.py` (senza dipendenze, supersampling subpixel 8x SDF)

---

## 1. Obiettivo: Oltre il Placeholder, con Carattere e Risoluzione Assoluta

I pulsanti attuali in `client/ui/ui.lua` usano tutti la stessa forma generica: un semplice rettangolo arrotondato grigio scuro (`forma.png`) con una linea di 3 pixel (`bordo.png`). Sebbene abbiano permesso di sviluppare rapidamente tutte le logiche di gioco, visivamente risultano neutri e uniformi.

Questa proposta introduce **Sagoma Tattica**, evoluzione naturale dello stile deciso da Sergio il 24 ottobre:
1. **Minimale, pulito e scuro**: Nessun kit finto-dipinto o skeuomorfo. Mantenimento rigoroso della palette vulcanica (`ui.C` carbone, contorno avorio chiaro, accenti del colore di squadra o di meccanica).
2. **Carattere geometrico distintivo**: Ogni categoria di controllo ha una sua **sagomatura fisica riconoscibile** (smussi a 45°, incavi per il Nucleo, piastre scanalate, gettoni sfaccettati).
3. **Resa grafica assoluta a qualsiasi densità di pixel**:
   - Gli asset non sono raster a bassa risoluzione: sono generati matematicamente tramite **Signed Distance Fields (SDF)** con **supersampling sub-pixel 8x (SS=8)** a 96×96 (e 80×80) compatibili 9-slice.
   - Su smartphone 1440p, monitor 4K e display iPad Retina a 400+ DPI, i bordi restano affilati e privi di sfocature o scalettature.

---

## 2. Le 7 Famiglie di Componenti: Ognuna con la sua Identità

```
+-------------------------------------------------------------------------------------------------+
| Famiglia                  | Asset Texture Generati       | Identità Geometrica e Funzione       |
+---------------------------+------------------------------+--------------------------------------+
| 1. Pulsante Eroe (Master) | eroe_forma.png, eroe_bordo   | Taglio asimmetrico 45°, culla Nucleo |
| 2. Menu Strutturali       | menu_forma.png, menu_bordo   | Piastra orizzontale, scanalatura sx  |
| 3. Slot Primarie (Brace)  | slot_arma_forma, slot_bordo  | Castone squadrato, badge munizioni   |
| 4. Slot Secondarie        | slot_arma_forma, slot_bordo  | Piastra acciaio con spia ricarica    |
| 5. Mobilità & Teleport    | gettone_forma, gettone_bordo | Gettone ottagonale runico concavo    |
| 6. Oggetti Tattici (Menta)| oggetto_forma, oggetto_bordo | Gettone esagonale compatto per arco  |
| 7. Controlli di Sistema   | sistema_forma, sistema_bordo | Modulo quadrato scanalato (back/gear)|
+-------------------------------------------------------------------------------------------------+
```

### 2.1 Pulsante Eroe / Master (`GIOCA`, `AVANTI`, `CONFERMA`)
- **Asset:** `eroe_forma.png`, `eroe_bordo.png` (96×96, Slice9 = 24).
- **Design:** Profilo a piastra vulcanica con **doppio chamfer diagonale a 45°** (angolo superiore destro e inferiore sinistro). Sulla sinistra integra l'incavo per il **Nucleo vivo** (alone additivo che pulsa al ritmo del respiro di battaglia). Sul fondo, un sottile accento luminoso del colore della squadra.
- **Feedback Tattile:** Pressione elastica morbida (scale 0.96) con bagliore che si intensifica al tocco.

### 2.2 Pulsanti Menu Strutturali (`CAMPAGNA`, `ALLENAMENTO`, `ARMERIA`, `EVENTI`)
- **Asset:** `menu_forma.png`, `menu_bordo.png` (96×96, Slice9 = 16).
- **Design:** Piastra orizzontale solida con scanalatura laterale sul bordo sinistro che ospita una micro-targhetta colorata (Oro per Campagna, Blu per Bot, Brace per Armeria, Rosso per Eventi). Sottotitolo integrato che guida immediatamente il giocatore sull'obiettivo della modalità.

### 2.3 Slot Armi Primarie da Battaglia (Brace `#ff6b2b`)
- **Asset:** `slot_arma_forma.png`, `slot_arma_bordo.png` (96×96, Slice9 = 20).
- **Design:** Alloggiamento rinforzato con angoli superiori smussati a 45°. L'arma attiva riceve il doppio bordo chiaro e l'alone brace. In alto a destra è incastonato il nuovo **badge munizioni ad alto contrasto** (`badge_forma.png`):
  - Quando restano 2 colpi: micro-pillola carbone con bordo brace.
  - Quando resta **1 solo colpo**: la pillola pulsa in oro d'avviso.

### 2.4 Slot Armi Secondarie da Battaglia (Acciaio `#9ec4e0`)
- **Asset:** `slot_arma_forma.png`, `slot_arma_bordo.png`.
- **Design:** Profilo metallico compatto con icona centrale a contrasto, distaccato dalle primarie per chiarezza di comando.

### 2.5 Gettone Mobilità & Teletrasporto (Viola `#c49cff`)
- **Asset:** `gettone_forma.png`, `gettone_bordo.png` (96×96, Slice9 = 24).
- **Design:** Sagoma **ottagonale runica** a rilievo concentrico, che richiama i Globi di fiammella. Il contatore numerico dei teletrasporti disponibili è inserito in una bolla protetta in alto a destra. Supporta il **doppio tocco rapido per il baratto** del 2° attacco.

### 2.6 Gettoni Oggetti Consumabili (Menta `#5cdbc0`)
- **Asset:** `oggetto_forma.png`, `oggetto_bordo.png` (80×80, Slice9 = 18).
- **Design:** Sagoma **esagonale compatta**. La forma esagonale permette un incastro perfetto lungo l'**arco radiale ergonomico** a 140 px attorno alla levetta di mira destra, liberando per sempre lo spazio verticale e lo slider dello zoom.

### 2.7 Controlli di Sistema (`Indietro`, `Rotellina / Impostazioni`, `Zoom`)
- **Asset:** `sistema_forma.png`, `sistema_bordo.png` (80×80, Slice9 = 18).
- **Design:** Moduli quadrati scanalati con angoli smussati e icone geometriche intagliate in negativo (nessuna linea sottile che rischia di perdersi ad alto zoom).

---

## 3. Schermata Impostazioni: Pulita e Senza Modali Pop-Up

In linea con la regola aurea di Sergio (*"Niente pop-up o finestre sopra il gioco, transizioni fluide sotto i 200 ms"*), la schermata delle impostazioni è strutturata in schede piane a due colonne:
1. **Modalità di Mira:** Scelta a levetta tattica tra `LANCETTA` (predefinita, 10 tacche con numeri in punta) e `MIRINO` (anellino concentrico).
2. **Feedback Aptico (Vibrazione):** Toggle animato a leva sagomata per attivare/disattivare la vibrazione al salto e allo sgancio mira.
3. **Controller:** Selezione della dinamica di sparo (Al rilascio della levetta vs Sul grilletto RT) con anteprima tasti del controller connesso.
4. **Zoom di Partenza:** Slider continuo con indicatore discreto del livello preferito all'avvio.

---

## 4. Come Integrare la Nuova Grafica nel Codice (`client/ui/ui.lua`)

Gli asset generati sono retrocompatibili e pronti all'uso:
1. **Aggiornamento di `client/ui/ui.atlas`**: Aggiunta delle nuove immagini (`eroe_forma.png`, `menu_forma.png`, `slot_arma_forma.png`, `gettone_forma.png`, `oggetto_forma.png`, `sistema_forma.png`, `badge_forma.png`).
2. **Mappatura in `client/ui/ui.lua`**:
   - Il metodo base `M.button(...)` può accettare un parametro opzionale `opt.tipo`:
     - `"eroe"` -> usa `eroe_forma` e `eroe_bordo` con `slice9 = (24, 24, 24, 24)`.
     - `"menu"` -> usa `menu_forma` e `menu_bordo` con `slice9 = (16, 16, 16, 16)`.
     - `"slot"` -> usa `slot_arma_forma` e `slot_arma_bordo` con `slice9 = (20, 20, 20, 20)`.
     - `"gettone"` -> usa `gettone_forma` e `gettone_bordo`.
     - `"oggetto"` -> usa `oggetto_forma` e `oggetto_bordo`.
     - Se omesso -> usa la base universale `forma`/`bordo` a 96×96 (nessun codice esistente si rompe).

---

## 5. Verifica Interattiva nel Prototipo Figma

Per provare con mano l'aspetto finale a schermo, cliccare sul file del prototipo interattivo:
👉 [megablast_ui_figma_prototype.html](file:///C:/Users/sergi/.gemini/antigravity/brain/379830d3-f680-4872-8e28-502c38140007/megablast_ui_figma_prototype.html)

Nel prototipo è possibile:
- Cambiare risoluzione (16:9 standard, 20:9 telefono largo, 4:3 iPad tablet).
- Navigare tra HUD di Battaglia, Home Menu, Armeria e Impostazioni.
- Cambiare il colore della squadra in tempo reale (Rosso, Blu, Verde, Giallo/Corona).
- Ispezionare ogni singolo pulsante con stati hover, active e disattivato.
