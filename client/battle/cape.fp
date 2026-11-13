#version 140

// Il mantello (battle/scoria.lua, battle/cloth.lua): il disegno intero del
// mantello, piegato lungo la catena simulata. Il nodo è un quadrato attorno
// al punto dove il mantello è attaccato; per ogni pixel si cerca il punto più
// vicino della catena: quanto è lungo la catena fin lì dice a che altezza del
// disegno siamo, quanto è di lato dice a che larghezza. A riposo la catena
// scende dritta e il disegno è com'è stato disegnato.
//
// Costanti (coordinate del nodo: da -0.5 a 0.5 sul lato del quadrato, y in su):
//   chain_a, chain_b, chain_c   i sei punti della catena (x, y, x, y)
//   frame   x, y: dov'è l'attacco nel disegno (0-1 da sinistra e dall'alto);
//           z, w: larghezza e altezza del disegno sul lato del nodo
// Il colore del nodo: b 1 normale, 0 tutto bianco (il lampo del colpo), a quanto si vede.
// L'immagine non sta in un atlante (scoria.lua la carica a parte): ha nell'angolo
// in alto a sinistra un pixel quasi trasparente che dice dov'è l'alto (sul
// telefono l'immagine caricata a parte può arrivare capovolta).

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

uniform fs_uniforms
{
    highp vec4 chain_a;
    highp vec4 chain_b;
    highp vec4 chain_c;
    highp vec4 frame;
};

void main()
{
    mediump float a = max(var_color.a, 0.0001);
    highp vec2 p = var_texcoord0 - 0.5;

    highp vec2 c[6];
    c[0] = chain_a.xy; c[1] = chain_a.zw;
    c[2] = chain_b.xy; c[3] = chain_b.zw;
    c[4] = chain_c.xy; c[5] = chain_c.zw;

    // il punto della catena più vicino: lunghezza fin lì (s) e distanza di lato (d)
    highp float best = 1e9;
    highp float s = 0.0;
    highp float d = 0.0;
    highp float run = 0.0;
    for (int i = 0; i < 5; i++) {
        highp vec2 a0 = c[i];
        highp vec2 seg = c[i + 1] - a0;
        highp float len = max(length(seg), 1e-5);
        highp vec2 dir = seg / len;
        highp float t = dot(p - a0, dir);
        // il primo tratto va anche sopra l'attacco (il colletto), l'ultimo oltre la fine
        highp float lo = i == 0 ? -1.0 : 0.0;
        highp float hi = i == 4 ? 1.0 : len;
        t = clamp(t, lo, hi);
        highp vec2 q = a0 + dir * t;
        highp float dist = length(p - q);
        if (dist < best) {
            best = dist;
            s = run + t;
            // di lato: positivo a destra della catena che scende (dir = (0, -1) -> x)
            d = dir.x * (p.y - q.y) - dir.y * (p.x - q.x);
        }
        run += len;
    }

    // nel disegno: x da sinistra, y dall'alto (0-1)
    highp vec2 uv = vec2(frame.x + d / frame.z, frame.y + s / frame.w);
    mediump float up = step(texture(texture_sampler, vec2(0.0005, 1.0 - 0.0005)).a,
                            texture(texture_sampler, vec2(0.0005, 0.0005)).a);
    mediump vec4 col = texture(texture_sampler, vec2(uv.x, mix(1.0 - uv.y, uv.y, up)));
    col *= step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
    mediump float white = 1.0 - var_color.b / a;
    out_fragColor = vec4(mix(col.rgb, vec3(col.a), white), col.a) * a;
}
