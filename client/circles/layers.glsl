// I piani degli sfondi dei gironi, fatti solo di forme (la ricetta di
// Gabriella, /mnt/project-files/gabriella/mappe_gironi: proposte_mappe_gironi.pdf,
// sorgente/mondo.py). Ogni girone ha il suo .fp che include questo file e
// mette i piani uno sopra l'altro, dal cielo al più vicino (forgia.fp).
//
// Le coordinate sono quelle della tavola: x verso destra, ys verso il basso,
// 0..1280 x 0..720 sulla schermata 16:9 (oltre, su 20:9 e 4:3, i piani
// continuano). Ogni piano scorre sempre nella stessa direzione alla sua
// velocità (vel: 1 = il piano di gioco, PASSO pixel al secondo) e si ripete
// identico ogni GIRO pixel, così non si vede mai uno stacco.
//
// px è quanti pixel del gioco fa un pixel dello schermo: i bordi sono morbidi
// di un pixel vero, senza scalini a nessuna risoluzione.

const highp float GIRO = 2560.0;
const highp float PASSO = 60.0;
const highp float FONDO_PIANO = 760.0;   // le sagome scendono fin sotto lo schermo

highp float caso(highp float n)
{
    n = fract(n * 0.1031);
    n *= n + 33.33;
    n *= n + n;
    return fract(n);
}

// 1 dentro (d < 0), 0 fuori, con un pixel dello schermo di passaggio
mediump float dentro(highp float d, highp float px)
{
    return clamp(0.5 - d / px, 0.0, 1.0);
}

// la x di un piano che scorre: verso -1 il piano va a sinistra, 1 a destra
highp float scorre(highp float x, highp float t, highp float vel, highp float verso)
{
    return mod(x - verso * t * PASSO * vel, GIRO);
}

// La luce dei piani pieni: in cima prende un po' di luce, in basso si scurisce
// (mondo.py poligoni3d). t: 0 in cima alla sagoma, 1 in fondo
mediump vec3 volume(mediump vec3 col, highp float t)
{
    if (t < 0.25) return mix(col, vec3(1.0), 0.12 * (1.0 - t / 0.25));
    return mix(col, vec3(0.0), 0.18 * (t - 0.25) / 0.75);
}

// Cielo: dall'alto al basso, e una sola luce che fa il bagliore (cx, cy, raggio)
mediump vec3 cielo(highp vec2 p, mediump vec3 alto, mediump vec3 basso)
{
    return mix(alto, basso, clamp(p.y / 720.0, 0.0, 1.0));
}

mediump vec3 bagliore(mediump vec3 col, highp vec2 p, highp vec3 luce, mediump vec3 colore, mediump float forza)
{
    mediump float a = forza * clamp(1.0 - length(p - luce.xy) / luce.z, 0.0, 1.0);
    return mix(col, colore, a);
}

// Fascia di nebbia ferma: più fitta a metà (y in alto, h alta)
mediump vec3 nebbia(mediump vec3 col, highp vec2 p, highp float y, highp float h, mediump vec3 colore, mediump float forza)
{
    mediump float a = forza * clamp(1.0 - abs(p.y - y - h * 0.5) / (h * 0.5), 0.0, 1.0);
    return mix(col, colore, a);
}

// Creste a spigoli dritti: un vertice a caso per ogni tratto largo "passo",
// alto fino ad "amp" sopra y0. Rende la ys della cima nel punto x
highp float vertice_x(highp float k, highp float n, highp float cw, highp float seme)
{
    return (k + 0.15 + 0.7 * caso(mod(k, n) * 1.7 + seme)) * cw;
}

highp float vertice_y(highp float k, highp float n, highp float y0, highp float amp, highp float seme)
{
    return y0 - amp * caso(mod(k, n) * 3.1 + seme + 0.5);
}

highp float cima_cresta(highp float x, highp float y0, highp float amp, highp float passo, highp float seme)
{
    highp float n = floor(GIRO / passo + 0.5);
    highp float cw = GIRO / n;
    highp float i = floor(x / cw);
    highp float k = x < vertice_x(i, n, cw, seme) ? i - 1.0 : i;
    highp float xa = vertice_x(k, n, cw, seme);
    highp float xb = vertice_x(k + 1.0, n, cw, seme);
    highp float f = (x - xa) / (xb - xa);
    return mix(vertice_y(k, n, y0, amp, seme), vertice_y(k + 1.0, n, y0, amp, seme), f);
}

mediump vec3 creste(mediump vec3 col, highp vec2 p, highp float t, highp float vel, highp float verso,
    highp float y0, highp float amp, highp float passo, highp float seme, mediump vec3 colore, highp float px)
{
    if (p.y < y0 - amp - px) return col;
    highp float x = scorre(p.x, t, vel, verso);
    highp float cima = cima_cresta(x, y0, amp, passo, seme);
    // il bordo inclinato: la distanza vera dal segmento è un po' meno della verticale
    mediump float a = dentro(cima - p.y, px * 1.4);
    if (a <= 0.0) return col;
    highp float alto = y0 - amp;
    return mix(col, volume(colore, (p.y - alto) / (FONDO_PIANO - alto)), a);
}

// Camini con il cappello (n sul giro, base a y0): metà verso la luce più
// chiara, l'altra in ombra (lato 1: la luce è a destra)
mediump vec3 camini(mediump vec3 col, highp vec2 p, highp float t, highp float vel, highp float verso,
    highp float y0, highp float n, highp float seme, highp float lato, mediump vec3 colore, highp float px)
{
    if (p.y < y0 - 340.0) return col;
    highp float x = scorre(p.x, t, vel, verso);
    highp float cw = GIRO / n;
    highp float i = floor(x / cw);
    highp float u = x - i * cw;
    highp float j = mod(i, n) + seme;
    highp float w = 34.0 + 26.0 * caso(j * 5.3);
    highp float h = 160.0 + 160.0 * caso(j * 7.9 + 0.3);
    highp float x0 = 8.0 + caso(j * 2.9 + 0.7) * (cw - w - 16.0);
    highp float cima = y0 - h;
    mediump float fusto = dentro(max(x0 - u, u - x0 - w), px) * dentro(cima - p.y, px);
    mediump float cappello = dentro(max(x0 - 8.0 - u, u - x0 - w - 8.0), px) * dentro(max(cima - 16.0 - p.y, p.y - cima), px);
    mediump float a = max(fusto, cappello);
    if (a <= 0.0) return col;
    bool chiaro = (u > x0 + w * 0.5) == (lato > 0.0);
    mediump vec3 c = chiaro ? mix(colore, vec3(1.0), 0.1) : mix(colore, vec3(0.0), 0.22);
    return mix(col, volume(c, (p.y - cima + 16.0) / (FONDO_PIANO - cima + 16.0)), a);
}

// Catene appese dall'alto (n sul giro): anelli a rombo e un peso in fondo
mediump vec3 catene(mediump vec3 col, highp vec2 p, highp float t, highp float vel, highp float verso,
    highp float n, highp float seme, mediump vec3 colore, highp float px)
{
    if (p.y > 410.0) return col;
    highp float x = scorre(p.x, t, vel, verso);
    highp float cw = GIRO / n;
    highp float i = floor(x / cw);
    highp float j = mod(i, n) + seme;
    highp float cx = i * cw + 20.0 + caso(j * 4.7) * (cw - 40.0);
    highp float l = 120.0 + 260.0 * caso(j * 6.1 + 0.2);
    highp float dx = abs(x - cx);
    if (dx > 12.0) return col;
    mediump float a = 0.0;
    if (p.y < l) {
        // gli anelli: uno ogni 16 pixel, alti 18 (si toccano)
        highp float k = floor((p.y + 10.0) / 16.0);
        for (int q = 0; q < 2; q++) {
            highp float yc = -10.0 + 16.0 * (k - float(q)) + 9.0;
            highp float d = (dx / 6.0 + abs(p.y - yc) / 9.0 - 1.0) * 4.99;
            a = max(a, dentro(abs(d) - 1.5, px));
        }
    } else if (p.y < l + 22.0) {
        a = dentro(dx - (10.0 - 6.0 * (p.y - l) / 22.0), px);
    }
    return mix(col, colore, a);
}

// Nubi a striscia (n sul giro, tra y0 e y1), che vanno avanti e indietro piano
mediump vec3 nubi(mediump vec3 col, highp vec2 p, highp float t, highp float vel, highp float verso,
    highp float n, highp float y0, highp float y1, highp float seme, mediump vec3 colore, mediump float forza, highp float px)
{
    if (p.y < y0 - 20.0 || p.y > y1 + 20.0) return col;
    highp float x = scorre(p.x, t, vel, verso);
    highp float cw = GIRO / n;
    highp float i = floor(x / cw);
    mediump float a = 0.0;
    for (int q = 0; q < 3; q++) {
        highp float k = i - float(q);
        highp float j = mod(k, n) + seme;
        highp float w = 140.0 + 180.0 * caso(j * 3.3);
        highp float r = caso(j * 8.1 + 0.4) < 0.34 ? 4.0 : (caso(j * 8.1 + 0.4) < 0.67 ? 6.0 : 9.0);
        highp float y = y0 + (y1 - y0) * caso(j * 5.7 + 0.9);
        highp float dur = 10.0 + 12.0 * caso(j * 1.9 + 0.6);
        highp float va = 60.0 * (0.5 - 0.5 * cos(3.14159 * t / dur));
        highp float x0 = k * cw + caso(j * 2.3 + 0.1) * cw + va;
        // una pillola: segmento orizzontale ingrossato di r
        highp float qx = clamp(x, x0 + r, x0 + w - r);
        highp float d = length(vec2(x - qx, p.y - y - r)) - r;
        a = max(a, dentro(d, px));
    }
    return mix(col, colore, a * forza);
}

// Braci che salgono e si spengono (n circa ogni 1280 x 720): ferme in x
mediump vec3 braci(mediump vec3 col, highp vec2 p, highp float t, mediump float quante,
    highp float seme, mediump vec3 colore, highp float px)
{
    const highp vec2 CELLA = vec2(128.0, 96.0);
    highp vec2 c = floor(p / CELLA);
    mediump float a = 0.0;
    for (int q = 0; q < 3; q++) {
        highp vec2 k = vec2(c.x, c.y + float(q));
        highp float j = mod(k.x, 20.0) * 31.7 + mod(k.y, 16.0) * 7.3 + seme;
        if (caso(j) > quante) continue;
        highp float d = 6.0 + 8.0 * caso(j * 1.3 + 0.2);
        highp float f = fract(t / d + caso(j * 2.1 + 0.5));
        highp vec2 b = (k + vec2(caso(j * 3.7 + 0.1), caso(j * 4.3 + 0.8))) * CELLA;
        b.y -= 220.0 * f;
        highp float r = (1.5 + 1.7 * caso(j * 5.9 + 0.3)) * 1.414;
        highp float dd = abs(p.x - b.x) + abs(p.y - b.y) - r;
        a = max(a, dentro(dd, px) * (0.5 + 0.5 * caso(j * 6.7)) * (1.0 - f));
    }
    return mix(col, colore, a);
}
