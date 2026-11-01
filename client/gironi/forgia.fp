#version 140

// Prologo, la Forgia (l'antinferno, casa dei diavoletti): lo sfondo della
// tavola di Gabriella, piano per piano dal più lontano (gironi2.py, FORGIA).
// Una sola luce: la bocca della fornace, arancio, a destra. Tutto scorre
// verso sinistra; nebbia e bagliore stanno fermi, le braci salgono.

#include "/gironi/strati.glsl"

in highp vec2 var_tavola;
in highp vec4 var_color;

out vec4 out_fragColor;

// le tinte del girone: dal fondo scuro verso la foschia (tinta in gironi2.py)
const mediump vec3 BASE = vec3(0.102, 0.043, 0.031);       // #1a0b08
const mediump vec3 FOSCHIA = vec3(0.690, 0.329, 0.173);    // #b0542c
const mediump vec3 CIELO_BASSO = vec3(0.353, 0.141, 0.078); // #5a2414
const mediump vec3 FUOCO = vec3(1.0, 0.478, 0.102);        // #ff7a1a
const mediump vec3 NUBI = vec3(0.071, 0.031, 0.024);       // #120806
const mediump vec3 VICINO = vec3(0.055, 0.020, 0.016);     // #0e0504
const mediump vec3 BRACE = vec3(1.0, 0.690, 0.227);        // #ffb03a
const highp float VERSO = -1.0;

mediump vec3 tinta(mediump float t) { return mix(BASE, FOSCHIA, t); }

void main()
{
    highp vec2 p = var_tavola;
    // il tempo (gironi/sfondo.lua): secondi interi in g, il resto in r
    highp float t = floor(var_color.g * 255.0 + 0.5) + var_color.r;
    highp float px = var_color.b * 4.0;

    mediump vec3 col = cielo(p, BASE, CIELO_BASSO);
    col = bagliore(col, p, vec3(980.0, 300.0, 460.0), FUOCO, 0.45);
    col = nubi(col, p, t, 0.04, VERSO, 10.0, 60.0, 220.0, 1.0, NUBI, 0.35, px);
    col = creste(col, p, t, 0.08, VERSO, 360.0, 130.0, 150.0, 2.0, tinta(0.7), px);
    col = camini(col, p, t, 0.15, VERSO, 420.0, 10.0, 3.0, 1.0, tinta(0.55), px);
    col = nebbia(col, p, 380.0, 150.0, FUOCO, 0.18);
    col = creste(col, p, t, 0.25, VERSO, 520.0, 110.0, 120.0, 4.0, tinta(0.4), px);
    col = camini(col, p, t, 0.4, VERSO, 600.0, 6.0, 5.0, 1.0, tinta(0.28), px);
    col = catene(col, p, t, 0.5, VERSO, 9.0, 6.0, tinta(0.32), px);
    col = creste(col, p, t, 0.75, VERSO, 690.0, 70.0, 90.0, 7.0, VICINO, px);
    col = braci(col, p, t, 0.67, 8.0, BRACE, px);
    // l'alfa del nodo: la schermata che lo usa può dissolverlo
    out_fragColor = vec4(col, 1.0) * var_color.a;
}
