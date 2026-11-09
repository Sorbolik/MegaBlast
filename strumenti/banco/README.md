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
