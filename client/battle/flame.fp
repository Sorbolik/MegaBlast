#version 140

// La fiammella viva (battle/flame.lua): l'immagine disegnata della fiamma,
// piegata in tempo reale. Niente fogli di animazione: la base resta ferma
// sulla testa e più si sale più la fiamma ondeggia, con due onde che salgono
// e un rumore morbido che scorre verso l'alto; l'altezza respira un poco.
// Si piega l'immagine, non la si cancella: il contorno nero resta intero.
//
// Il colore del nodo dice cosa fare (moltiplicato per l'alfa, come in gui):
//   r  la parte frazionaria del tempo (secondi)
//   g  i secondi interi (0-15) / 255, + 128 / 255 per i capelli di Favilla
//   b  1 normale, 0 tutto bianco (il lampo del colpo, come battle/flash.fp)
//   a  quanto si vede
// L'immagine non sta in un atlante (battle/flame.lua la carica a parte): le
// coordinate vanno da 0 a 1 sull'immagine intera.

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

// tutto torna uguale dopo 16 secondi: le onde girano un numero intero di volte
// (multipli di GIRO = 2pi/16) e il rumore sale di 12 caselle (0,75 al secondo)
const highp float GIRO = 0.39269908;
const highp float SALE = 0.75;
// il margine attorno alla testa di Favilla (battle/flame.lua M.PAD)
const highp float PAD = 0.06;

highp float hash(highp vec2 p)
{
    p.y = mod(p.y, 12.0);
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// rumore morbido (value noise), da 0 a 1
highp float noise(highp vec2 p)
{
    highp vec2 i = floor(p);
    highp vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// quanto si piega un punto dei capelli di Favilla: zero sul viso e sulle corna
// (l'immagine della testa, battle/flame.lua HAIR), uno sulle ciocche di fuori
mediump float hair_weight(highp vec2 p)
{
    // il viso con le orecchie: un'ellisse larga in basso; le corna: due ovali sopra
    highp float face = length((p - vec2(0.56, 0.28)) / vec2(0.58, 0.36));
    highp float horn_l = length((p - vec2(0.50, 0.62)) / vec2(0.11, 0.13));
    highp float horn_r = length((p - vec2(0.78, 0.60)) / vec2(0.11, 0.13));
    highp float d = min(face, min(horn_l, horn_r));
    return smoothstep(1.0, 1.6, d);
}

void main()
{
    mediump float a = max(var_color.a, 0.0001);
    highp float sec = floor(var_color.g / a * 255.0 + 0.5);
    mediump float hair = step(127.5, sec);
    highp float t = sec - hair * 128.0 + var_color.r / a;

    // Dov'è il basso nell'immagine: sul PC le coordinate scendono, sul telefono
    // l'immagine caricata a parte può arrivare con le coordinate che salgono (9 nov:
    // su Favilla si muoveva il viso e non i capelli). Lo si chiede all'immagine:
    // un punto pieno vicino al fondo e vuoto alla stessa altezza dall'alto.
    highp vec2 probe = hair < 0.5 ? vec2(0.5, 0.03) : vec2(0.35, 0.08);
    mediump float down = step(texture(texture_sampler, vec2(probe.x, probe.y)).a,
                              texture(texture_sampler, vec2(probe.x, 1.0 - probe.y)).a);
    // y da 0 (giù) a 1 (su)
    highp vec2 p = vec2(var_texcoord0.x, mix(var_texcoord0.y, 1.0 - var_texcoord0.y, down));

    mediump float w;
    highp vec2 d;
    if (hair < 0.5) {
        // la fiammella: la base (in fondo all'immagine) ferma, la punta libera
        mediump float h = clamp((p.y - 0.02) / 0.80, 0.0, 1.0);
        w = h * sqrt(h);
        highp float n = noise(vec2(p.x * 3.0, p.y * 3.5 - t * SALE)) - 0.5;
        d.x = w * (0.040 * sin(t * GIRO * 13.0 - p.y * 6.0)
                 + 0.018 * sin(t * GIRO * 23.0 - p.y * 13.0 + 1.3)
                 + 0.050 * n);
        // l'altezza respira: la fiamma si allunga e si accorcia dalla base
        highp float s = 1.0 + 0.06 * sin(t * GIRO * 10.0) + 0.03 * sin(t * GIRO * 18.0 + 0.7);
        d.y = (p.y - 0.02) * (1.0 - 1.0 / s);
    } else {
        // le ciocche di Favilla: più lente e più piccole, dal viso in fuori.
        // Il nodo è più grande della testa di PAD per lato (battle/flame.lua)
        p = (p - PAD) / (1.0 - 2.0 * PAD);
        w = hair_weight(p);
        highp float n = noise(vec2(p.x * 4.0, p.y * 4.0 - t * SALE)) - 0.5;
        d.x = w * (0.016 * sin(t * GIRO * 10.0 - p.y * 9.0) + 0.020 * n);
        d.y = w * 0.010 * sin(t * GIRO * 13.0 - p.x * 7.0 + 0.5);
    }

    highp vec2 q = p - d;
    mediump vec4 c = texture(texture_sampler, vec2(q.x, mix(q.y, 1.0 - q.y, down)), -0.5);
    // fuori dall'immagine non c'è niente (i bordi sono trasparenti)
    c *= step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0);
    mediump float white = 1.0 - var_color.b / a;
    out_fragColor = vec4(mix(c.rgb, vec3(c.a), white), c.a) * a;
}
