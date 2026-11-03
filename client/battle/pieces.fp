#version 140

// I pezzi tinti del diavoletto (battle/scoria.lua): come il materiale gui di
// Defold, ma con le immagini rimpicciolite (mipmap) un po' più grandi del
// solito (-0,5), così da lontano il diavoletto resta più nitido (Sergio, 2 nov)

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

void main()
{
    out_fragColor = texture(texture_sampler, var_texcoord0.xy, -0.5) * var_color;
}
