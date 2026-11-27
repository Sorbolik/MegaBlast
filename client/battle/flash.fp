#version 140

// Il lampo bianco del colpo sul diavoletto (battle/scoria.lua): il verde del
// colore del nodo dice quanto è bianco, 1 normale e 0 tutto bianco. Il blu dice
// quanto colore resta (1 tutto, 0 grigio) e il rosso quanto è chiaro: sono la
// cenere dei tasti dell'HUD che ora non si possono usare (game.gui_script,
// CP.hand.ASH; Sergio, 23 nov). L'alfa resta quella del nodo.
// Le immagini rimpicciolite (mipmap) un po' più grandi del solito (-0,5): da
// lontano il diavoletto resta più nitido (Sergio, 2 nov; come pieces.fp)
// La costante band (per nodo, gui.set) accesa (w 1) fa invece la fascia lucente che
// passa sul piedistallo della home (menu/home.lua), sommata sopra il disegno: x il
// mezzo della fascia in pixel della finestra, y mezza larghezza, z quanto è forte.
// Dritta e piena come col ritaglio di prima, ma col bordo di un pixel sfumato: scorre
// liscia anche fra un pixel e l'altro (Sergio, 24 nov).
// Con z negativo la luce ha il colore del nodo invece del caldo e la forza è -z: la
// stessa fascia sulle cornici delle card dei pezzi, del colore del loro posto
// (menu/gear_ui.lua, ui/sheen.lua; Sergio, 27 nov).

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;
in highp vec2 var_pos;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

uniform fs_uniforms
{
    highp vec4 band;
};

const mediump vec3 LUCE = vec3(1.0, 0.72, 0.3);

void main()
{
    mediump vec4 t = texture(texture_sampler, var_texcoord0.xy, -0.5);
    if (band.w > 0.5) {
        mediump float k = clamp(band.y - abs(var_pos.x - band.x) + 0.5, 0.0, 1.0);
        mediump vec3 luce = band.z < 0.0 ? var_color.rgb / max(var_color.a, 0.0001) : LUCE;
        out_fragColor = vec4(t.rgb * luce * (k * abs(band.z)) * var_color.a, 0.0);
        return;
    }
    mediump float a = max(var_color.a, 0.0001);
    mediump float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
    mediump vec3 c = mix(vec3(l), t.rgb, var_color.b / a) * (var_color.r / a);
    mediump float q = 1.0 - var_color.g / a;
    out_fragColor = vec4(mix(c, vec3(t.a), q), t.a) * var_color.a;
}
