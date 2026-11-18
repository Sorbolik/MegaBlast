#version 140

// The passes over the silhouettes' images (render/lit.render_script,
// menu/outline.lua), one node drawn over all of the image each time:
//
// pass.y 0 and 1 close the slits of the silhouettes of the places: first every
// point takes the most of what is around it (the pieces grow by pass.z pixels),
// then the least (they shrink back). What was nearer than twice that stays
// joined: the two boots' hems that nearly touch, a horn on its helmet, a
// shoulder pad on the armour become one shape, and the contour does not go in
// between.
//
// pass.y 2 makes the soft field of the glow: for each place, how much of what is
// seen around a point (pass.z pixels) is a piece of that place. Half at the edge
// of a piece, fading to nothing away from it: battle/outline.fp makes the glow
// from it.
//   pass   y: 0 grow, 1 shrink, 2 glow; z: by how many pixels; x, w unused
//   rect   z, w: the image's size in pixels

out vec4 out_fragColor;

uniform mediump sampler2D sagome_src;

uniform fs_uniforms
{
    highp vec4 rect;
    mediump vec4 pass;
};

const int N = 8;

// what is seen at a point of the "v" image, a weight for each place
mediump vec4 seen_at(highp vec2 uv)
{
    mediump vec3 v = texture(sagome_src, uv).rgb;
    mediump float v4 = min(v.r, min(v.g, v.b));
    return vec4(v - v4, v4);
}

void main()
{
    highp vec2 uv = gl_FragCoord.xy / rect.zw;
    if (pass.y > 1.5) {
        mediump vec4 sum = seen_at(uv);
        for (int i = 0; i < N; i++) {
            highp float a = 6.2831853 * (float(i) + 0.5) / float(N);
            highp vec2 d = vec2(cos(a), sin(a)) / rect.zw * pass.z;
            sum += seen_at(uv + d) + seen_at(uv + d * 0.66) * 0.8 + seen_at(uv + d * 0.33) * 0.5;
        }
        out_fragColor = sum / (1.0 + float(N) * 2.3);
        return;
    }
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
