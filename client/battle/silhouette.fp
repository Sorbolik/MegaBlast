#version 140

// The silhouettes of the worn pieces, for the lit contour of the menus
// (menu/outline.lua, render/lit.render_script). A second devil, never seen, is
// drawn with this material into two images:
//   pass 0  where each place's pieces are, covered or not: one channel per
//           place (place, from the material), added up;
//   pass 1  what is in front at each point: a piece of a place writes its color
//           (r, g, b for the first three, white for the fourth), the rest of the
//           devil writes black over it;
//   pass 2  where the black line of the drawing in front is (red).

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
    mediump vec4 t = texture(texture_sampler, var_texcoord0.xy);
    mediump float a = t.a;
    if (pass.x < 0.5) {
        out_fragColor = place * a;
    } else if (pass.x > 1.5) {
        mediump float ink = 1.0 - smoothstep(0.14, 0.22, max(t.r, max(t.g, t.b)) / max(a, 0.0001));
        out_fragColor = vec4(ink * a, 0.0, 0.0, a);
    } else {
        out_fragColor = vec4((place.rgb + place.a) * a, a);
    }
}
