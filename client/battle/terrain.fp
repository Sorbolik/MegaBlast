#version 140

// Tutta la mappa in un solo rettangolo opaco: sfondo a strati, terreno dipinto
// ritagliato dalla maschera di collisione, parete e brace dei crateri.
// maschera: r = terreno adesso, g = terreno all'inizio (760 x 360 celle: la mappa con 60 celle di margine per lato,
// filtro lineare, così i bordi escono morbidi invece che a scalini), b = distanza
// dal cratere più vicino (cerchi veri, non celle: game.gui_script, crateri).
// Le texture sono a alfa premoltiplicato.
//
// Lo sfondo è dipinto (Sergio, 2 nov): un cielo e tre strisce (lontano, medio,
// vicino) fatte da SVG (strumenti/grafica/mappe_dipinte.py), ognuna larga un
// giro, che si ripetono di lato, seguono la camera in parallasse (si spostano
// meno della mappa, così sembrano lontane) e scorrono piano da sole (il
// «movimento calmo»), con braci che salgono. Un cratere mostra lo sfondo, con
// un orlo bruciato sul terreno attorno; il terreno fa ombra sullo sfondo.

in mediump vec2 var_uv;
in highp vec2 var_schermo;
in highp float var_zoom;

out vec4 out_fragColor;

uniform mediump sampler2D terreno;
uniform mediump sampler2D maschera;
uniform mediump sampler2D cielo;
uniform mediump sampler2D lontano;
uniform mediump sampler2D medio;
uniform mediump sampler2D davanti;

uniform fs_uniforms
{
    // x = 1 solo lo sfondo (la home); y = secondi; zw = quanto lo schermo è
    // più largo e più alto di 16:9 (ui/screen.lua: kx, ky)
    mediump vec4 opzioni;
    // per ogni striscia dello sfondo dipinto: dove comincia dall'alto e quanto è
    // alta (diviso 720), quanto segue la camera, quanto è già scorsa (pixel della scena)
    highp vec4 striscia1;
    highp vec4 striscia2;
    highp vec4 striscia3;
};

const mediump vec2 CELLA = vec2(1.0 / 760.0, 1.0 / 360.0);
// maschera e terreno dipinto coprono la mappa più un margine per lato (180 unità del
// mondo su 1920): var_uv va da 0 a 1 sulla mappa, la texture da -MARGINE a 1 + MARGINE
const mediump float MARGINE = 180.0 / 1920.0;

// lo sfondo è misurato su una mappa di 1280 x 720 (var_zoom è già riportato lì)
const highp vec2 MONDO = vec2(1280.0, 720.0);
const highp vec2 CENTRO = vec2(640.0, 360.0);
// le braci dello sfondo dipinto: oro spento, il rosso acceso è dei personaggi
const mediump vec3 BRACE_SPENTA = vec3(0.86, 0.66, 0.36);
// l'orlo bruciato attorno ai crateri che mostrano lo sfondo
const mediump vec3 BRUCIATO = vec3(0.078, 0.047, 0.031);
// l'orlo bruciato attorno ai crateri, in unità del mondo (una cella è 3)
const mediump float ORLO = 14.0;
// lo sfondo dipinto è largo un giro (2560 pixel della scena), poi si ripete
const highp float GIRO = 2560.0;

highp float caso(highp float n)
{
    n = fract(n * 0.1031);
    n *= n + 33.33;
    n *= n + n;
    return fract(n);
}

// Dove si vede il punto di una fila lontana: con la camera si sposta di
// "quanto" (0 = ferma, 1 = come la mappa), e anche lo zoom la ingrandisce meno
// var_schermo e var_zoom sono stirati su 1280 x 720: qui tornano senza deformazioni
highp vec2 schermo()
{
    return CENTRO + (var_schermo - CENTRO) * opzioni.zw;
}

highp float zoom()
{
    return var_zoom * opzioni.z;
}

// lz = log2(zoom()), uguale per tutto lo schermo: calcolato una volta in
// sfondo(), così ogni fila fa solo un exp2 invece di un pow (OPT-001 A1)
highp vec2 fila(highp vec2 camera, highp float quanto, highp float lz)
{
    return CENTRO + (camera - CENTRO) * quanto + (schermo() - CENTRO) * exp2(-quanto * lz);
}

// Braci che salgono piano, vicine (si spostano quasi come la mappa)
mediump float braci(highp vec2 camera, highp float t, highp float lz)
{
    highp vec2 q = fila(camera, 0.8, lz);
    q.y -= t * 16.0;
    q.x += sin(t * 0.6 + q.y * 0.013) * 10.0;
    highp vec2 cella = floor(q / 52.0);
    highp float r = caso(cella.x * 7.31 + cella.y * 91.7);
    // il 72% delle celle non ha brace: niente altro conto (OPT-001 A2)
    if (r < 0.72) return 0.0;
    highp vec2 punto = (vec2(caso(r * 53.1 + 1.0), caso(r * 17.9 + 2.0)) * 0.8 + 0.1) * 52.0;
    highp float d = length(q - cella * 52.0 - punto);
    return smoothstep(2.4, 0.3, d) * (0.55 + 0.45 * sin(t * 2.7 + r * 40.0));
}

// Una striscia dello sfondo dipinto sopra col (alfa premoltiplicato): sotto il
// suo fondo continua l'ultima riga, sopra non c'è niente
mediump vec3 striscia(mediump vec3 col, mediump sampler2D img, highp vec4 s, highp vec2 camera, highp float lz)
{
    highp vec2 q = fila(camera, s.z, lz);
    highp float dall_alto = ((MONDO.y - q.y) / MONDO.y - s.x) / s.y;
    if (dall_alto < 0.0) return col;
    highp float u = fract((q.x + s.w) / GIRO);
    mediump vec4 c = texture(img, vec2(u, 1.0 - min(dall_alto, 1.0)));
    return col * (1.0 - c.a) + c.rgb;
}

mediump vec3 sfondo()
{
    // il punto del mondo al centro dello schermo
    highp vec2 camera = var_uv * MONDO - (schermo() - CENTRO) / zoom();
    highp float lz = log2(zoom());
    highp vec2 q = fila(camera, 0.02, lz) / MONDO;
    mediump vec3 col = texture(cielo, clamp(q, 0.0, 1.0)).rgb;
    col = striscia(col, lontano, striscia1, camera, lz);
    col = striscia(col, medio, striscia2, camera, lz);
    col += BRACE_SPENTA * braci(camera, opzioni.y, lz) * 0.45;
    col = striscia(col, davanti, striscia3, camera, lz);
    // più scuro ai bordi dello schermo
    highp vec2 v = (var_schermo - CENTRO) / CENTRO;
    return col * (1.0 - 0.18 * dot(v, v));
}

void main()
{
    // b della maschera: distanza dal bordo del cratere più vicino, in unità del
    // mondo (8 livelli per unità, 128 sul bordo, negativa dentro). Interpolata fra
    // le celle resta un cerchio vero; fwidth: un pixel dello schermo, per un bordo
    // netto a ogni zoom. Letta prima dei ritorni, perché fwidth vuole tutti i pixel
    mediump vec2 muv = vec2((var_uv.x + MARGINE) / (1.0 + 2.0 * MARGINE), var_uv.y);
    mediump vec3 m = texture(maschera, muv).rgb;
    mediump float dc = (m.b * 255.0 - 128.0) * 0.125;
    // (mai zero: smoothstep con i due bordi uguali non è definito)
    mediump float aa = max(fwidth(dc) * 0.5, 0.01);
    // sotto la mappa (la camera ci scende perché l'HUD non copra il terreno):
    // il baratro, sempre più buio (niente bagliore: partiva di colpo dal fondo della mappa e
    // faceva una riga netta, Sergio 6 nov)
    if (var_uv.y < 0.0 && opzioni.x < 0.5) {
        highp float giu = -var_uv.y * 1080.0;
        mediump vec3 col = sfondo() * (1.0 - smoothstep(0.0, 160.0, giu) * 0.75);
        out_fragColor = vec4(col, 1.0);
        return;
    }
    // la home, e le bande attorno alla mappa (che la camera mostra da lontano):
    // solo lo sfondo
    if (opzioni.x > 0.5 || muv.x < 0.0 || muv.x > 1.0 || var_uv.y > 1.0) {
        out_fragColor = vec4(sfondo(), 1.0);
        return;
    }
    mediump vec4 ter = texture(terreno, muv);

    // il cratere è il cerchio dell'esplosione (b), che toglie anche il disegno che
    // sporge sopra le celle piene (il contorno in cima al pavimento), più le celle
    // scavate (g c'era terreno all'inizio, r adesso non più) di crateri che b non
    // conosce (per sicurezza: un buco a celle, ristretto, che dentro un cerchio
    // noto non si vede)
    mediump float scavato = clamp(m.g - m.r, 0.0, 1.0);
    mediump float buco = max(1.0 - smoothstep(-aa, aa, dc), smoothstep(0.6, 0.9, scavato));

    // lo sfondo solo dove il terreno non lo copre tutto
    mediump vec3 col = vec3(0.0);
    if (ter.a * (1.0 - buco) < 0.999) {
        col = sfondo();
        // il terreno fa ombra sullo sfondo, in basso a destra: lo stacca
        mediump float ombra = texture(maschera, muv + vec2(-1.5, 2.5) * CELLA).r * 0.55
            + texture(maschera, muv + vec2(-3.5, 6.0) * CELLA).r * 0.3;
        col *= 1.0 - ombra * 0.7;
    }
    // il cratere mostra lo sfondo; il terreno attorno ha l'orlo bruciato
    if (dc < ORLO) {
        mediump float orlo = 1.0 - smoothstep(ORLO * 0.35, ORLO, dc);
        ter.rgb = mix(ter.rgb, BRUCIATO * ter.a, orlo * 0.92);
    }
    ter *= 1.0 - buco;

    col = col * (1.0 - ter.a) + ter.rgb;
    out_fragColor = vec4(col, 1.0);
}
