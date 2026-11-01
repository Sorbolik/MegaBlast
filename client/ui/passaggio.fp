#version 140

// Il velo dei passaggi tra le schermate (ui/passaggio.lua): un nodo grande come
// tutto lo schermo. Il colore del nodo dice cosa fare:
//   r  il raggio del buco dell'iride (0 tutto coperto, 1 tutto aperto)
//   g  0 nero (l'iride), 1 il carbone della UI (lo scivolo)
//   a  quanto copre
// Il bordo dell'iride è morbido di un paio di pixel.

// dal vertex shader dei gironi (gironi/girone.vp): il punto in pixel del gioco
// e il colore del nodo così com'è
in highp vec2 var_tavola;
in highp vec4 var_color;

out vec4 out_fragColor;

const mediump vec3 FONDO = vec3(0.051, 0.047, 0.063);   // ui.C.FONDO

void main()
{
    highp vec2 p = var_tavola - vec2(640.0, 360.0);
    mediump float a = var_color.a;
    highp float r = var_color.r * 1000.0;
    mediump float g = var_color.g;
    mediump float copre = a * clamp((length(p) - r) / 3.0 + 0.5, 0.0, 1.0);
    out_fragColor = vec4(FONDO * g * copre, copre);
}
