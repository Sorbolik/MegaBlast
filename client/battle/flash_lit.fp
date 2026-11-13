#version 140

// The devil's pieces in battle with the white hit flash (battle/scoria.lua):
// flash.fp (the node color's green says how white; mipmaps biased -0.5) lit
// by the battle's lights (battle/light.glsl, battle/lights.lua), before the white.

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;
in highp vec2 var_pos;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

#include "/battle/light.glsl"

void main()
{
    mediump vec4 t = lit(texture_sampler, texture(texture_sampler, var_texcoord0.xy, -0.5), var_texcoord0.xy, var_pos);
    mediump float q = 1.0 - var_color.g / max(var_color.a, 0.0001);
    out_fragColor = vec4(mix(t.rgb, vec3(t.a), q), t.a) * var_color.a;
}
