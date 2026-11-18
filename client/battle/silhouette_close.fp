#version 140

// Closes the slits of the silhouettes of the places (render/lit.render_script,
// menu/outline.lua): first every point takes the most of what is around it
// (pass.y 0: the pieces grow by pass.z pixels), then the least (pass.y 1: they
// shrink back). What was nearer than twice that stays joined: the two boots'
// hems that nearly touch, a horn on its helmet, a shoulder pad on the armour
// become one shape, and the contour does not go in between.
//   pass   y: 0 grow, 1 shrink; z: by how many pixels; x, w unused
//   rect   z, w: the image's size in pixels

out vec4 out_fragColor;

uniform mediump sampler2D sagome_src;

uniform fs_uniforms
{
    highp vec4 rect;
    mediump vec4 pass;
};

const int N = 12;

void main()
{
    highp vec2 uv = gl_FragCoord.xy / rect.zw;
    mediump vec4 c = texture(sagome_src, uv);
    for (int i = 0; i < N; i++) {
        highp float a = 6.2831853 * (float(i) + 0.5) / float(N);
        highp vec2 d = vec2(cos(a), sin(a)) / rect.zw * pass.z;
        mediump vec4 s1 = texture(sagome_src, uv + d);
        mediump vec4 s2 = texture(sagome_src, uv + d * 0.5);
        c = pass.y < 0.5 ? max(c, max(s1, s2)) : min(c, min(s1, s2));
    }
    out_fragColor = c;
}
