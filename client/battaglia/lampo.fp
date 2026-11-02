#version 140

// Il lampo bianco del colpo sul diavoletto (battaglia/scoria.lua): il verde del
// colore del nodo dice quanto è bianco, 1 normale e 0 tutto bianco. Gli altri
// canali non tingono; l'alfa resta quella del nodo.
// Le immagini rimpicciolite (mipmap) un po' più grandi del solito (-0,5): da
// lontano il diavoletto resta più nitido (Sergio, 2 nov; come pezzi.fp)

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

void main()
{
    mediump vec4 t = texture(texture_sampler, var_texcoord0.xy, -0.5);
    mediump float q = 1.0 - var_color.g / max(var_color.a, 0.0001);
    out_fragColor = vec4(mix(t.rgb, vec3(t.a), q), t.a) * var_color.a;
}
