# Il tema di colore di ogni girone per le scene dipinte.
# tinta = la tinta delle ombre dello sfondo (0-1, ruota dei colori); sempre lontana dal rosso del personaggio.
def T(gradi, sat_s, sat_g, l0, l1, luce, foschia, tg=None):
    return dict(tinta=gradi / 360, sat_sfondo=sat_s, sat_gioco=sat_g, l0=l0, l1=l1, luce=luce, foschia=foschia,
                tinta_gioco=(gradi if tg is None else tg) / 360)

TEMI = {
    "forgia":     T(235, .20, .14, .05, .95, "#e9a46a", "#3d3a4a", 215),
    "limbo":      T(160, .18, .22, .08, .92, "#efe9cf", "#a7b4ac", 140),
    "lussuria":   T(268, .30, .22, .06, .95, "#cdbcff", "#5b4a7a", 250),
    "gola":       T(85,  .20, .22, .07, .93, "#c9ccb1", "#6b6e5c", 70),
    "avarizia":   T(48,  .26, .26, .06, .92, "#e8c77a", "#6a5838", 45),
    "ira":        T(185, .28, .24, .05, .95, "#9fd0c8", "#2f4f52", 165),
    "eresia":     T(222, .22, .14, .05, .95, "#e7a36b", "#3a3a4a", 230),
    "violenza":   T(300, .20, .16, .06, .95, "#e8b88c", "#4e3a4c", 285),
    "frode":      T(78,  .22, .18, .05, .95, "#b9cf72", "#34392b", 90),
    "tradimento": T(205, .30, .26, .06, .95, "#cfefff", "#3e5d78", 200),
    "purgatorio": T(205, .30, .26, .08, .86, "#fff1c9", "#c9d8e2", 100),
    "paradiso":   T(245, .32, .24, .06, .92, "#fff1a8", "#6a63a8", 48),
}
