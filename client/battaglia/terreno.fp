#version 140

// Tutta la mappa in un solo rettangolo opaco: sfondo a strati, terreno dipinto
// ritagliato dalla maschera di collisione, parete e brace dei crateri.
// maschera: r = terreno adesso, g = terreno all'inizio (640 x 360 celle,
// filtro lineare, così i bordi escono morbidi invece che a scalini).
// Le texture sono a alfa premoltiplicato.
//
// Lo sfondo non è un disegno: è un cielo con tre file di guglie e colline
// sempre più vicine, poi braci che salgono. Ogni fila si sposta con la camera
// meno della mappa (parallasse), così sembra lontana. Colori freddi e spenti,
// il terreno davanti caldo e con un'ombra: si stacca dallo sfondo.

in mediump vec2 var_uv;
in highp vec2 var_schermo;
in highp float var_zoom;

out vec4 out_fragColor;

uniform mediump sampler2D terreno;
uniform mediump sampler2D interno;
uniform mediump sampler2D maschera;

uniform fs_uniforms
{
    // x = 1 mappa dipinta, 0 mappa senza disegno; y = secondi; zw = quanto lo
    // schermo è più largo e più alto di 16:9 (ui/schermo.lua: kx, ky)
    mediump vec4 opzioni;
};

const mediump vec2 CELLA = vec2(1.0 / 640.0, 1.0 / 360.0);
const mediump vec3 BRACE = vec3(1.0, 0.478, 0.102);
const mediump vec3 BRACE_CHIARA = vec3(1.0, 0.769, 0.42);
const mediump vec3 ROCCIA = vec3(0.23, 0.21, 0.26);
const mediump vec3 OTTONE = vec3(0.86, 0.64, 0.32);

// lo sfondo è misurato su una mappa di 1280 x 720 (var_zoom è già riportato lì)
const highp vec2 MONDO = vec2(1280.0, 720.0);
const highp vec2 CENTRO = vec2(640.0, 360.0);
const mediump vec3 CIELO_ALTO = vec3(0.03, 0.035, 0.07);
const mediump vec3 ORIZZONTE = vec3(0.22, 0.17, 0.27);
const mediump vec3 BAGLIORE = vec3(0.6, 0.24, 0.09);

highp float caso(highp float n)
{
    n = fract(n * 0.1031);
    n *= n + 33.33;
    n *= n + n;
    return fract(n);
}

highp float rumore(highp float x)
{
    highp float i = floor(x);
    highp float f = fract(x);
    return mix(caso(i), caso(i + 1.0), f * f * (3.0 - 2.0 * f));
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

highp vec2 fila(highp vec2 camera, highp float quanto)
{
    return CENTRO + (camera - CENTRO) * quanto + (schermo() - CENTRO) * pow(zoom(), -quanto);
}

// Profilo di una fila (0..~1.8): colline morbide e ogni tanto una guglia stretta
highp float profilo(highp float x, highp float scala, highp float seme)
{
    highp float u = x / scala + seme;
    highp float h = rumore(u) * 0.62 + rumore(u * 2.3 + 7.1) * 0.26 + rumore(u * 6.1 + 3.0) * 0.12;
    highp float c = u * 1.3;
    highp float r = caso(floor(c) + seme * 13.0);
    highp float largo = 0.06 + 0.1 * caso(floor(c) + 5.0);
    highp float guglia = step(0.62, r) * (0.7 + 2.5 * (r - 0.62)) * clamp(1.0 - abs(fract(c) - 0.5) / largo, 0.0, 1.0);
    return max(h, h * 0.4 + guglia);
}

// Una fila sopra lo sfondo: colore pieno sotto il profilo e un po' di nebbia
// in basso, che la separa dalla fila davanti
mediump vec3 aggiungi_fila(mediump vec3 col, highp vec2 camera, highp float quanto, highp float base,
    highp float alto, highp float scala, highp float seme, mediump vec3 colore)
{
    highp vec2 q = fila(camera, quanto);
    highp float h = base + alto * profilo(q.x, scala, seme);
    highp float bordo = 1.2 * pow(zoom(), -quanto);
    col = mix(col, colore, clamp((h - q.y) / bordo + 0.5, 0.0, 1.0));
    return mix(col, ORIZZONTE, smoothstep(base + alto * 0.3, base - 90.0, q.y) * 0.3);
}

// Braci che salgono piano, vicine (si spostano quasi come la mappa)
mediump float braci(highp vec2 camera, highp float t)
{
    highp vec2 q = fila(camera, 0.8);
    q.y -= t * 16.0;
    q.x += sin(t * 0.6 + q.y * 0.013) * 10.0;
    highp vec2 cella = floor(q / 52.0);
    highp float r = caso(cella.x * 7.31 + cella.y * 91.7);
    highp vec2 punto = (vec2(caso(r * 53.1 + 1.0), caso(r * 17.9 + 2.0)) * 0.8 + 0.1) * 52.0;
    highp float d = length(q - cella * 52.0 - punto);
    return step(0.72, r) * smoothstep(2.4, 0.3, d) * (0.55 + 0.45 * sin(t * 2.7 + r * 40.0));
}

mediump vec3 sfondo()
{
    // il punto del mondo al centro dello schermo
    highp vec2 camera = var_uv * MONDO - (schermo() - CENTRO) / zoom();
    highp vec2 q = fila(camera, 0.04);
    mediump vec3 col = mix(ORIZZONTE, CIELO_ALTO, smoothstep(140.0, 700.0, q.y));
    col += BAGLIORE * exp(-max(q.y, 0.0) / 110.0) * 0.5;
    col = aggiungi_fila(col, camera, 0.12, 250.0, 200.0, 240.0, 1.7, vec3(0.18, 0.145, 0.225));
    col = aggiungi_fila(col, camera, 0.28, 150.0, 230.0, 160.0, 4.3, vec3(0.125, 0.105, 0.165));
    col = aggiungi_fila(col, camera, 0.5, 30.0, 220.0, 115.0, 9.1, vec3(0.06, 0.055, 0.085));
    col += BRACE * braci(camera, opzioni.y) * 0.7;
    // più scuro ai bordi dello schermo
    highp vec2 v = (var_schermo - CENTRO) / CENTRO;
    return col * (1.0 - 0.22 * dot(v, v));
}

// quanto terreno c'è attorno a uv, a distanza r celle (8 direzioni)
mediump float vicino(mediump vec2 uv, mediump float r)
{
    mediump vec2 d = CELLA * r;
    mediump vec2 e = d * 0.7071;
    mediump float n = texture(maschera, uv + vec2(d.x, 0.0)).r;
    n = max(n, texture(maschera, uv - vec2(d.x, 0.0)).r);
    n = max(n, texture(maschera, uv + vec2(0.0, d.y)).r);
    n = max(n, texture(maschera, uv - vec2(0.0, d.y)).r);
    n = max(n, texture(maschera, uv + e).r);
    n = max(n, texture(maschera, uv - e).r);
    n = max(n, texture(maschera, uv + vec2(e.x, -e.y)).r);
    n = max(n, texture(maschera, uv + vec2(-e.x, e.y)).r);
    return n;
}

void main()
{
    // sotto la mappa (la camera ci scende perché l'HUD non copra il terreno):
    // il baratro, sempre più buio, con il bagliore della brace appena sotto il bordo
    if (var_uv.y < 0.0) {
        highp float giu = -var_uv.y * 1080.0;
        mediump vec3 col = sfondo() * (1.0 - smoothstep(0.0, 160.0, giu) * 0.75);
        col += BRACE * exp(-giu / 45.0) * 0.18;
        out_fragColor = vec4(col, 1.0);
        return;
    }
    mediump vec2 m = texture(maschera, var_uv).rg;
    mediump vec4 ter;
    if (opzioni.x > 0.5) {
        ter = texture(terreno, var_uv);
    } else {
        // mappa senza disegno: roccia scura con il bordo superiore più chiaro
        mediump float sopra = texture(maschera, var_uv + vec2(0.0, CELLA.y * 2.0)).r;
        mediump vec3 c = mix(ROCCIA * 1.9, ROCCIA, sopra);
        ter = vec4(c, 1.0) * smoothstep(0.35, 0.65, m.r);
    }

    // costruito = adesso c'è terreno dove all'inizio non c'era (il Bastione):
    // conci di pietra col bordo scuro e la cima d'ottone, come le piattaforme
    mediump float costruito = clamp(m.r - m.g, 0.0, 1.0);
    if (costruito > 0.0) {
        mediump float pieno = min(
            min(texture(maschera, var_uv + vec2(CELLA.x, 0.0)).r, texture(maschera, var_uv - vec2(CELLA.x, 0.0)).r),
            min(texture(maschera, var_uv + vec2(0.0, CELLA.y)).r, texture(maschera, var_uv - vec2(0.0, CELLA.y)).r));
        // i conci: file alte 2 celle, giunti ogni 8 celle sfalsati di 4
        highp vec2 q = var_uv * vec2(640.0, 360.0);
        highp float fila = floor(q.y * 0.5);
        mediump float giunto = max(step(fract(q.y * 0.5), 0.12),
            step(fract((q.x + mod(fila, 2.0) * 4.0) * 0.125), 0.045));
        mediump vec3 pietra = ROCCIA * (1.6 + 0.3 * caso(fila * 7.0 + floor((q.x + mod(fila, 2.0) * 4.0) * 0.125)));
        pietra = mix(pietra, ROCCIA * 0.7, giunto);
        // bordo scuro tutto attorno, d'ottone sopra (come le cime delle piattaforme)
        mediump float cima = 1.0 - texture(maschera, var_uv + vec2(0.0, CELLA.y)).r;
        mediump vec3 c = mix(pietra, ROCCIA * 0.5, smoothstep(0.1, 0.65, 1.0 - pieno));
        c = mix(c, OTTONE, smoothstep(0.3, 0.8, cima));
        ter = mix(ter, vec4(c, 1.0), costruito);
    }

    // scavato = c'era terreno all'inizio e adesso non c'è più
    mediump float scavato = clamp(m.g - m.r, 0.0, 1.0);

    // lo sfondo solo dove il terreno non lo copre tutto
    mediump vec3 col = vec3(0.0);
    if (ter.a * (1.0 - scavato) < 0.999) {
        col = sfondo();
        // il terreno fa ombra sullo sfondo, in basso a destra: lo stacca
        mediump float ombra = texture(maschera, var_uv + vec2(-1.5, 2.5) * CELLA).r * 0.55
            + texture(maschera, var_uv + vec2(-3.5, 6.0) * CELLA).r * 0.3;
        col *= 1.0 - ombra * 0.7;
    }
    if (scavato > 0.0) {
        mediump float n1 = vicino(var_uv, 1.5);
        mediump float n2 = vicino(var_uv, 4.5);
        mediump vec4 parete = texture(interno, var_uv);
        mediump float a = scavato * max(n1, n2 * 0.75);
        col = col * (1.0 - parete.a * a) + parete.rgb * a;
        mediump float brace = scavato * n1;
        col += mix(BRACE, BRACE_CHIARA, n1 * n1) * brace * 0.85;
        ter *= 1.0 - scavato;
    }

    col = col * (1.0 - ter.a) + ter.rgb;
    out_fragColor = vec4(col, 1.0);
}
