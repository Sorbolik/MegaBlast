#version 140

// The silhouettes of the worn pieces, for the lit contour of the menus
// (menu/outline.lua, render/lit.render_script). A second devil, never seen, is
// drawn with this material into two images:
//   pass 0  where each place's pieces are, covered or not: one channel per
//           place (place, from the material), added up;
//   pass 1  what is in front at each point: a piece of a place writes its color
//           (r, g, b for the first three, white for the fourth), the rest of the
//           devil writes black over it.

in mediump vec2 var_texcoord0;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

uniform fs_uniforms
{
    mediump vec4 place;
    mediump vec4 pass;
};

void main()
{
    mediump float a = texture(texture_sampler, var_texcoord0.xy).a;
    if (pass.x < 0.5) {
        out_fragColor = place * a;
    } else {
        out_fragColor = vec4((place.rgb + place.a) * a, a);
    }
}
