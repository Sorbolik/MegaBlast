---
name: progetta-meccanica
description: Trasforma un'idea grezza per MegaBlast (arma, regola, mappa, modalità, schermata) in una scheda di design pronta da implementare. Usala quando Sergio propone qualcosa di nuovo o chiede "come lo faresti?".
---

# Progetta una meccanica

Porta un'idea da "mi piacerebbe che..." a una scheda breve che un programmatore
può implementare senza indovinare. Il documento di riferimento del gioco è
[docs/design.md](../../../docs/design.md): leggilo prima, e non contraddirlo
senza dirlo.

## 1. Capisci di che taglia è

| Tipo | Esempio | Dove va |
|---|---|---|
| Taratura | "danno spada da 35 a 40" | solo la tabella del punto 3 |
| Ritocco | "il pugno spinge anche chi lo usa" | scheda corta |
| Aggiunta | "nuova arma delle casse" | scheda completa |
| Sistema nuovo | "equipaggiamento", "negozio", "campagna" | scheda completa, e spezzala in passi piccoli |

Se l'idea è ambigua, scegli la lettura più probabile, scrivi quale hai scelto e
vai avanti. Fai al massimo una domanda, e solo se la risposta cambia il gioco.

## 2. Controlla che stia nel gioco

Le decisioni già prese (in `docs/design.md` e nella memoria del progetto) sono
vincoli, non suggerimenti:

- A turni, partite brevi (turno 15 s, partita massimo 3 minuti), online con server autoritativo.
- Niente vento. Niente pay-to-win: in partita contano solo abilità e strategia.
- Mobile prima di tutto: controlli touch semplici, fluido anche su telefoni economici.
- Minimalismo: la soluzione più leggera vince.
- Stile "Le Scorie" per tutto quello che si vede.

Se l'idea ne viola uno, dillo subito e proponi la variante che lo rispetta.

## 3. Scrivi la scheda

Per una taratura basta la tabella dei numeri. Per il resto usa queste sezioni,
corte:

```markdown
## <Nome>

**In una frase**: cosa fa, dal punto di vista del giocatore.
**Sensazione**: cosa deve provare chi la usa (es. "colpo da maestro", "panico").
**Perché serve**: quale buco del gioco riempie o quale scelta nuova crea.

### Regole
Elenco numerato, preciso: quando si attiva, cosa succede tick per tick se serve,
quando finisce. Niente "circa" o "un po'".

### Numeri
| Costante | Valore | Perché |
Le costanti vivono in `client/sim/game.lua` (`M.NOME`, in tick a 60 al secondo
e pixel). Riusa quelle che esistono, nomina quelle nuove.

### Casi limite
Bordo mappa, fuori mappa, contro acciaio, su un altro robot, durante la
ritirata, allo scadere del turno o della partita, con più oggetti in volo.

### Cosa tocca
- Simulazione (`client/sim/`), quindi anche il server, che la esegue uguale.
- Protocollo (messaggi nuovi o campi nuovi in `docs/design.md` §5).
- Client: HUD, disegno, animazioni, suoni.

### Come si verifica
Criteri misurabili, ognuno controllabile con un test in `tests/sim_test.lua` o
uno scenario in `strumenti/simula/scenari/`. "È divertente" non è un criterio;
"il secondo colpo arriva entro 20 tick dal teletrasporto" sì.
```

## 4. Consegna

- Fai passare la scheda da [valuta-meccanica](../valuta-meccanica/SKILL.md) prima di implementarla.
- Quando Sergio la approva, aggiorna `docs/design.md` (la tabella armi, le regole)
  nella stessa PR dell'implementazione, così il documento resta vero.
- Per implementarla segui [sviluppa-meccanica](../sviluppa-meccanica/SKILL.md).
