# Banco di prova delle armi

Ogni arma da sola contro un bersaglio fermo (1000 di vita, a terra), niente bot:

```bash
luajit strumenti/banco/banco.lua                  # tutte le armi (primarie, secondarie, Lama)
luajit strumenti/banco/banco.lua eagle mallet     # solo alcune
luajit strumenti/banco/banco.lua --md banco.md    # scrive anche la tabella
```

Prova distanze, angoli e forze, spara una volta e misura nella simulazione: danno
massimo di un colpo, gittata (distanza massima con un colpo a segno), colpi per
uccidere da 100 e spinta massima. Le armi si trovano da `game.CRATE_WEAPONS` e
`game.DRAFT_SECONDARIES`: quelle nuove compaiono da sole. Una che non spara nella
prova risulta **NON VALUTATO**. Sono numeri misurati su una griglia: la gittata ha
la risoluzione della griglia. È la base del referto del
[dottore del design](../../.claude/skills/dottore-del-design/SKILL.md).

## Duelli (bot contro bot, un'arma a testa)

```bash
bash strumenti/banco/duelli.sh 8                  # tutte le coppie d'armi, 8 coppie di partite ciascuna, tutti i core
bash strumenti/banco/duelli.sh 8 eagle sword      # solo alcune armi
luajit strumenti/banco/duelli.lua eagle sword --coppie 8   # una coppia sola
```

1v1, senza casse, ogni robot ha solo la sua arma (99 colpi, quindi le primarie non
finiscono) e la Lama. Ogni coppia è la stessa partita (seme e mappa) due volte con le
armi scambiate: chi comincia e la mappa si annullano, e un'arma contro se stessa fa
esattamente 50%. Scrive `simulazione/banco/duelli.md` (vittorie medie e matrice). Con
8 coppie (16 partite per accoppiamento) l'errore è di circa ±12 punti: servono più
coppie per distinguere armi vicine. Non è il gioco vero (casse, draft, munizioni
limitate): dice quale arma vince quando il bot la sa usare. Il tempo: circa 3 secondi a
partita, 21 minuti su 4 core per tutte le armi con 8 coppie.
