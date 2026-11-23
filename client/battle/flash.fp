#version 140

// Il lampo bianco del colpo sul diavoletto (battle/scoria.lua): il verde del
// colore del nodo dice quanto è bianco, 1 normale e 0 tutto bianco. Il blu dice
// quanto colore resta (1 tutto, 0 grigio) e il rosso quanto è chiaro: sono la
// cenere dei tasti dell'HUD che ora non si possono usare (game.gui_script,
// CP.hand.ASH; Sergio, 23 nov). L'alfa resta quella del nodo.
// Le immagini rimpicciolite (mipmap) un po' più grandi del solito (-0,5): da
// lontano il diavoletto resta più nitido (Sergio, 2 nov; come pieces.fp)

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

void main()
{
    mediump vec4 t = texture(texture_sampler, var_texcoord0.xy, -0.5);
    mediump float a = max(var_color.a, 0.0001);
    mediump float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
    mediump vec3 c = mix(vec3(l), t.rgb, var_color.b / a) * (var_color.r / a);
    mediump float q = 1.0 - var_color.g / a;
    out_fragColor = vec4(mix(c, vec3(t.a), q), t.a) * var_color.a;
}
