#version 140

// The tinted pieces of the devils in battle (battle/scoria.lua): pieces.fp
// lit by the battle's lights (battle/light.glsl, battle/lights.lua).

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;
in highp vec2 var_pos;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

#include "/battle/light.glsl"

void main()
{
    vec4 t = lit(texture_sampler, texture(texture_sampler, var_texcoord0.xy, -0.5), var_texcoord0.xy, var_pos);
    out_fragColor = t * var_color;
}
