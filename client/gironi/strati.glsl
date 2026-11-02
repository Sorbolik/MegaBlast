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

// ---------------------------------------------------------------------------
// Lo stile dipinto (documento delle mappe dell'apprendista, dipinto.py): ogni
// sagoma piena prende una sfumatura, in alto la luce del girone e in basso la
// foschia, e sulla parte bassa il tratteggio a righe oblique delle ombre
// dell'apprendista. Poi raggi, foschia bassa, polvere, angoli scuri e grana.

// t: 0 in cima alla sagoma, 1 in fondo (FONDO_PIANO); hx: la x che scorre
// col piano, così il tratteggio va con la sagoma
mediump vec3 pieno(mediump vec3 col, mediump float a, mediump vec3 base, highp float t, highp float hx, highp vec2 p,
    mediump vec3 luce, mediump vec3 foschia, highp float px)
{
    if (a <= 0.0) return col;
    mediump vec3 c = t < 0.55 ? mix(mix(base, luce, 0.12), base, t / 0.55)
                             : mix(base, mix(base, foschia, 0.45), (t - 0.55) / 0.45);
    // righe a -35 gradi ogni 7 pixel, spesse 1,3, che compaiono dal 35% in giù
    mediump float m = 0.75 * clamp((t - 0.35) / 0.65, 0.0, 1.0);
    if (m > 0.0) {
        highp float r = hx * 0.819 + p.y * 0.574;
        highp float d = abs(fract(r / 7.0) - 0.5) * 7.0;
        c = mix(c, vec3(0.0), 0.55 * m * dentro(d - 0.65, px));
    }
    return mix(col, c, a);
}

mediump float t_sagoma(highp float y, highp float cima)
{
    return clamp((y - cima) / (FONDO_PIANO - cima), 0.0, 1.0);
}

// Creste a cime piatte (le alture del Limbo): ogni vertice è un pianoro largo
// metà del passo, e fra due pianori il pendio è dritto
mediump vec3 creste_piatte(mediump vec3 col, highp vec2 p, highp float t, highp float vel, highp float verso,
    highp float y0, highp float amp, highp float passo, highp float seme, mediump vec3 colore,
    mediump vec3 luce, mediump vec3 foschia, highp float px)
{
    highp float alto = y0 - amp;
    if (p.y < alto - px) return col;
    highp float x = scorre(p.x, t, vel, verso);
    highp float n = floor(GIRO / passo + 0.5);
    highp float cw = GIRO / n;
    highp float q = cw * 0.25;
    highp float i = floor(x / cw);
    highp float xi = (i + 0.25 + 0.5 * caso(mod(i, n) * 1.7 + seme)) * cw;
    highp float cima;
    if (abs(x - xi) <= q) {
        cima = vertice_y(i, n, y0, amp, seme);
    } else {
        highp float k = x < xi ? i - 1.0 : i;
        highp float xa = (k + 0.25 + 0.5 * caso(mod(k, n) * 1.7 + seme)) * cw + q;
        highp float xb = (k + 1.25 + 0.5 * caso(mod(k + 1.0, n) * 1.7 + seme)) * cw - q;
        cima = mix(vertice_y(k, n, y0, amp, seme), vertice_y(k + 1.0, n, y0, amp, seme), clamp((x - xa) / (xb - xa), 0.0, 1.0));
    }
    mediump float a = dentro(cima - p.y, px * 1.4);
    return pieno(col, a, colore, t_sagoma(p.y, alto), x, p, luce, foschia, px);
}

// Mura merlate (cima a y0 - alto, merli larghi e alti "merlo") e, davanti,
// torri a punta: n sul giro, base a yt, larghe w0..w1 e alte h0..h1
mediump vec3 castello(mediump vec3 col, highp vec2 p, highp float t, highp float vel, highp float verso,
    highp float y0, highp float alto, highp float merlo, highp float yt, highp float n, highp vec2 w, highp vec2 h,
    highp float seme, mediump vec3 colore, mediump vec3 luce, mediump vec3 foschia, highp float px)
{
    if (p.y < min(y0 - alto - merlo, yt - h.y - w.y) - px) return col;
    highp float x = scorre(p.x, t, vel, verso);
    // le mura: sopra la linea dei merli piena, i merli uno sì e uno no
    highp float cm = y0 - alto - merlo;
    highp float dm = mod(x, merlo);
    highp float bordo = min(dm, merlo - dm);
    highp float dentro_merlo = mod(x, merlo * 2.0) < merlo ? bordo : -bordo;
    mediump float a = max(dentro(y0 - alto - p.y, px), dentro(-dentro_merlo, px) * dentro(cm - p.y, px));
    col = pieno(col, a, colore, t_sagoma(p.y, cm), x, p, luce, foschia, px);
    // le torri
    highp float cw = GIRO / n;
    highp float i = floor(x / cw);
    highp float j = mod(i, n) + seme;
    highp float ww = mix(w.x, w.y, caso(j * 5.3));
    highp float hh = mix(h.x, h.y, caso(j * 7.9 + 0.3));
    highp float x0 = i * cw + 8.0 + caso(j * 2.9 + 0.7) * (cw - ww - 16.0);
    highp float u = x - x0;
    highp float top = yt - hh;
    highp float punta = ww * 0.9 * (1.0 - abs(u - ww * 0.5) / (ww * 0.5));
    mediump float at = dentro(max(-u, u - ww), px) * dentro(top - punta - p.y, px * 1.4);
    return pieno(col, at, colore, t_sagoma(p.y, top - ww * 0.9), x, p, luce, foschia, px);
}

// Colonne spezzate (n sul giro, base a y0, alte h0..h1, larghe 18..30): la
// cima rotta è una spezzata di tre tratti
mediump vec3 colonne(mediump vec3 col, highp vec2 p, highp float t, highp float vel, highp float verso,
    highp float y0, highp float n, highp vec2 h, highp float seme, mediump vec3 colore,
    mediump vec3 luce, mediump vec3 foschia, highp float px)
{
    if (p.y < y0 - h.y - 8.0) return col;
    highp float x = scorre(p.x, t, vel, verso);
    highp float cw = GIRO / n;
    highp float i = floor(x / cw);
    highp float j = mod(i, n) + seme;
    highp float w = 18.0 + 12.0 * caso(j * 5.3);
    highp float hh = mix(h.x, h.y, caso(j * 7.9 + 0.3));
    highp float x0 = i * cw + 4.0 + caso(j * 2.9 + 0.7) * (cw - w - 8.0);
    highp float u = (x - x0) / w;
    highp float top = y0 - hh;
    // (0, 0) (0.4, +8) (0.7, -6) (1, +4)
    highp float cima = u < 0.4 ? mix(0.0, 8.0, u / 0.4) : (u < 0.7 ? mix(8.0, -6.0, (u - 0.4) / 0.3) : mix(-6.0, 4.0, (u - 0.7) / 0.3));
    mediump float a = dentro(max(-u, u - 1.0) * w, px) * dentro(top + cima - p.y, px * 1.4);
    return pieno(col, a, colore, t_sagoma(p.y, top - 6.0), x, p, luce, foschia, px);
}

// Raggi di luce leggeri da (lx, ly): sette spicchi fermi
mediump vec3 raggi(mediump vec3 col, highp vec2 p, highp vec2 l, highp float seme, mediump vec3 luce)
{
    highp float dy = p.y - l.y;
    if (dy <= 0.0) return col;
    mediump float a = 0.0;
    for (int i = 0; i < 7; i++) {
        highp float k = float(i) + seme;
        highp float s = -0.9 + 1.8 * caso(k * 3.7);
        highp float w = 30.0 + 60.0 * caso(k * 5.1 + 0.3);
        highp float d = abs(p.x - l.x - s * dy) - w * dy / 900.0;
        a += (0.03 + 0.04 * caso(k * 2.3 + 0.7)) * clamp(0.5 - d / 2.0, 0.0, 1.0);
    }
    // in modo "schermo": schiarisce soltanto
    return col + (vec3(1.0) - col) * luce * a;
}

// Acqua sotto le piattaforme (dall'altezza y), con la cresta a zigzag che ondeggia
mediump vec3 acqua(mediump vec3 col, highp vec2 p, highp float t, highp float y, mediump vec3 colore,
    mediump vec3 cresta, highp float px)
{
    if (p.y < y - 8.0) return col;
    highp float x = p.x + 8.0 * sin(t * 0.9);
    highp float z = abs(fract(x / 40.0) - 0.5) * 12.0;   // 0..6: l20,-6 l20,6
    mediump float a = dentro(y - 6.0 + z - p.y, px);
    col = mix(col, colore, a);
    col = mix(col, cresta, dentro(abs(p.y - (y - 6.0 + z)) - 1.5, px));
    highp float x2 = p.x + 20.0 - 6.0 * sin(t * 0.7 + 1.0);
    highp float z2 = abs(fract(x2 / 60.0) - 0.5) * 8.0;
    return mix(col, cresta, 0.5 * dentro(abs(p.y - (y + 18.0 - 4.0 + z2)) - 1.0, px));
}

// Polvere sospesa (circa n ogni 1280 x 720): pallini che galleggiano quasi fermi
mediump vec3 polvere(mediump vec3 col, highp vec2 p, highp float t, mediump float quante,
    highp float seme, mediump vec3 colore, highp float px)
{
    const highp vec2 CELLA = vec2(128.0, 96.0);
    highp vec2 c = floor(p / CELLA);
    mediump float a = 0.0;
    for (int q = -1; q < 1; q++) {
        for (int r = -1; r < 1; r++) {
            highp vec2 k = c + vec2(float(q) + step(0.5, fract(p.x / CELLA.x)), float(r) + step(0.5, fract(p.y / CELLA.y)));
            highp float j = mod(k.x, 20.0) * 31.7 + mod(k.y, 16.0) * 7.3 + seme;
            if (caso(j) > quante) continue;
            highp float d = 9.0 + 9.0 * caso(j * 1.3 + 0.2);
            highp float f = 6.2832 * (t / (d * 2.0) + caso(j * 2.1 + 0.5));
            highp vec2 b = (k + vec2(caso(j * 3.7 + 0.1), caso(j * 4.3 + 0.8))) * CELLA + vec2(14.0 * sin(f), 10.0 * sin(f * 0.7 + 1.3));
            highp float rr = 1.0 + 1.4 * caso(j * 5.9 + 0.3);
            a = max(a, dentro(length(p - b) - rr, px) * (0.3 + 0.4 * caso(j * 6.7)));
        }
    }
    return mix(col, colore, a);
}

// Foschia bassa fra lo sfondo e il piano di gioco (dal 30% dell'altezza in giù)
mediump vec3 foschia_bassa(mediump vec3 col, highp vec2 p, mediump vec3 colore)
{
    return mix(col, colore, 0.45 * clamp((p.y / 720.0 - 0.3) / 0.7, 0.0, 1.0));
}

// Angoli più scuri e grana di carta (in pixel veri dello schermo)
mediump vec3 carta(mediump vec3 col, highp vec2 p, highp vec2 schermo)
{
    highp vec2 v = (p - vec2(640.0, 331.0)) / vec2(960.0, 540.0);
    col *= 1.0 - 0.55 * clamp((length(v) - 0.55) / 0.45, 0.0, 1.0);
    // a chicchi di due pixel veri, leggera: su uno sfondo chiaro si vede di più
    highp float g = caso(dot(floor(schermo * 0.5), vec2(1.0, 157.0)) * 0.37);
    mediump float a = 0.16 * clamp(1.4 * g - 0.55, 0.0, 1.0);
    return col * mix(vec3(1.0), vec3(0.5, 0.4, 0.3), a);
}
