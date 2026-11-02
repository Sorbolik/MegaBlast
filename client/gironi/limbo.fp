#version 140

// Girone I, il Limbo (il castello dei sette muri): lo sfondo della tavola di
// Gabriella (gironi2.py, LIMBO), dipinto come nel documento delle mappe
// dell'apprendista (dipinto.py, tema "limbo": una sola tinta verde salvia,
// sfumature, tratteggio, raggi, foschia, grana). Il girone più luminoso: la
// luce viene dall'alto, al centro. Tutto scorre verso sinistra.

#include "/gironi/strati.glsl"

in highp vec2 var_tavola;
in highp vec4 var_color;

out vec4 out_fragColor;

// i colori di gironi2.py passati dal tema del girone (temi.py, grade "sfondo")
const mediump vec3 CIELO_ALTO = vec3(0.243, 0.275, 0.267);  // #3e4644
const mediump vec3 CIELO_BASSO = vec3(0.553, 0.588, 0.576); // #8d9693
const mediump vec3 NUBI = vec3(0.918, 0.933, 0.925);        // #eaeeec
const mediump vec3 LONTANO = vec3(0.592, 0.616, 0.608);     // #979d9b
const mediump vec3 CASTELLO = vec3(0.506, 0.529, 0.522);    // #818785
const mediump vec3 MURA = vec3(0.451, 0.475, 0.467);        // #737977
const mediump vec3 COLONNE = vec3(0.337, 0.361, 0.353);     // #565c5a
const mediump vec3 VICINO = vec3(0.153, 0.173, 0.165);      // #272c2a
const mediump vec3 NEBBIA = vec3(0.839, 0.886, 0.863);      // #d6e2dc
const mediump vec3 LUCE = vec3(0.937, 0.914, 0.812);        // #efe9cf
const mediump vec3 FOSCHIA = vec3(0.655, 0.706, 0.675);     // #a7b4ac
const mediump vec3 POLVERE = vec3(0.933, 0.953, 0.918);     // #eef3ea
const mediump vec3 ACQUA = vec3(0.302, 0.412, 0.337);       // #4d6956
const mediump vec3 CRESTA = vec3(0.702, 0.792, 0.733);      // #b3cabb
const highp float VERSO = -1.0;

void main()
{
    highp vec2 p = var_tavola;
    highp float t = floor(var_color.g * 255.0 + 0.5) + var_color.r;
    highp float px = var_color.b * 4.0;

    mediump vec3 col = cielo(p, CIELO_ALTO, CIELO_BASSO);
    col = bagliore(col, p, vec3(640.0, -60.0, 560.0), LUCE, 0.5);
    col = nubi(col, p, t, 0.04, VERSO, 16.0, 60.0, 260.0, 1.0, NUBI, 0.14, px);
    col = raggi(col, p, vec2(640.0, -60.0), 7.0, LUCE);
    col = creste_piatte(col, p, t, 0.07, VERSO, 320.0, 70.0, 220.0, 2.0, LONTANO, LUCE, FOSCHIA, px);
    col = castello(col, p, t, 0.13, VERSO, 470.0, 110.0, 18.0, 380.0, 7.0, vec2(50.0, 70.0), vec2(90.0, 170.0), 3.0,
        CASTELLO, LUCE, FOSCHIA, px);
    col = nebbia(col, p, 400.0, 150.0, NEBBIA, 0.32);
    col = castello(col, p, t, 0.25, VERSO, 600.0, 60.0, 26.0, 560.0, 5.0, vec2(40.0, 60.0), vec2(60.0, 120.0), 4.0,
        MURA, LUCE, FOSCHIA, px);
    col = colonne(col, p, t, 0.4, VERSO, 720.0, 14.0, vec2(80.0, 220.0), 5.0, COLONNE, LUCE, FOSCHIA, px);
    col = nebbia(col, p, 560.0, 140.0, NEBBIA, 0.25);
    col = colonne(col, p, t, 0.75, VERSO, 760.0, 8.0, vec2(120.0, 300.0), 6.0, VICINO, LUCE, FOSCHIA, px);
    col = foschia_bassa(col, p, FOSCHIA);
    col = acqua(col, p, t, 680.0, ACQUA, CRESTA, px);
    col = polvere(col, p, t, 0.45, 8.0, POLVERE, px);
    col = carta(col, p, gl_FragCoord.xy);
    out_fragColor = vec4(col, 1.0) * var_color.a;
}
