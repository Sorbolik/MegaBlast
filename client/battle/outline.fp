#version 140

// The lit contour of the worn pieces in the menus (menu/outline.lua): one line
// along the outer edge of each place (helmet with horns, armour with shoulder
// pads, the two boots, the gloves), nothing inside. A point is lit when the
// piece in front there is of a place (sagome_v) and the outside of that place's
// whole silhouette (sagome_u, the pieces of the place together) is nearer than
// the line's width. Where the body covers a piece the line stops.
//   rect    the window rectangle the two images cover (x, y, w, h in pixels)
//   width   x: the line's width in window pixels
//   c1-c4   each place's color (alpha 0: not lit)

out vec4 out_fragColor;

uniform mediump sampler2D sagome_u;
uniform mediump sampler2D sagome_v;

uniform fs_uniforms
{
    highp vec4 rect;
    mediump vec4 width;
    mediump vec4 c1;
    mediump vec4 c2;
    mediump vec4 c3;
    mediump vec4 c4;
};

const int N = 24;

void main()
{
    highp vec2 uv = (gl_FragCoord.xy - rect.xy) / rect.zw;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) discard;
    mediump vec3 v = texture(sagome_v, uv).rgb;
    mediump float v4 = min(v.r, min(v.g, v.b));
    mediump vec4 seen = vec4(v - v4, v4);
    if (seen.r + seen.g + seen.b + seen.a < 0.004) discard;

    // The least of the silhouette around, on two rings so the line is full. A
    // point around counts as outside only if a little farther the same way is
    // outside too: a slit between two pieces of the place (the hems of the two
    // boots that nearly touch) is not an edge.
    mediump vec4 least = vec4(1.0);
    for (int i = 0; i < N; i++) {
        highp float a = 6.2831853 * (float(i) + 0.5) / float(N);
        highp vec2 d = vec2(cos(a), sin(a)) / rect.zw * width.x;
        mediump vec4 far = max(max(texture(sagome_u, uv + d * 2.4), texture(sagome_u, uv + d * 3.6)), texture(sagome_u, uv + d * 5.0));
        least = min(least, max(texture(sagome_u, uv + d), far));
        least = min(least, max(texture(sagome_u, uv + d * 0.5), far));
    }
    mediump vec4 edge = seen * smoothstep(0.0, 0.5, 1.0 - least);
    mediump vec4 col = c1 * edge.r + c2 * edge.g + c3 * edge.b + c4 * edge.a;
    out_fragColor = vec4(col.rgb, col.a);
}
