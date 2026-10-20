#version 140

// Tutta la mappa in un solo rettangolo opaco: sfondo lontano, terreno dipinto
// ritagliato dalla maschera di collisione, parete e brace dei crateri.
// maschera: r = terreno adesso, g = terreno all'inizio (640 x 360 celle,
// filtro lineare, così i bordi escono morbidi invece che a scalini).
// Le texture sono a alfa premoltiplicato.

in mediump vec2 var_uv;

out vec4 out_fragColor;

uniform mediump sampler2D sfondo;
uniform mediump sampler2D terreno;
uniform mediump sampler2D interno;
uniform mediump sampler2D maschera;

uniform fs_uniforms
{
    mediump vec4 opzioni; // x = 1 mappa dipinta, 0 mappa senza disegno
};

const mediump vec2 CELLA = vec2(1.0 / 640.0, 1.0 / 360.0);
const mediump vec3 BRACE = vec3(1.0, 0.478, 0.102);
const mediump vec3 BRACE_CHIARA = vec3(1.0, 0.769, 0.42);
const mediump vec3 ROCCIA = vec3(0.23, 0.21, 0.26);

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
    mediump vec2 m = texture(maschera, var_uv).rg;
    mediump vec3 col = texture(sfondo, var_uv).rgb;

    mediump vec4 ter;
    if (opzioni.x > 0.5) {
        ter = texture(terreno, var_uv);
    } else {
        // mappa senza disegno: roccia scura con il bordo superiore più chiaro
        mediump float sopra = texture(maschera, var_uv + vec2(0.0, CELLA.y * 2.0)).r;
        mediump vec3 c = mix(ROCCIA * 1.9, ROCCIA, sopra);
        ter = vec4(c, 1.0) * smoothstep(0.35, 0.65, m.r);
    }

    // scavato = c'era terreno all'inizio e adesso non c'è più
    mediump float scavato = clamp(m.g - m.r, 0.0, 1.0);
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
