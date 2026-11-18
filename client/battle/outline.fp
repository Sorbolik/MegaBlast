#version 140

// The lit contour of the worn pieces in the menus (menu/outline.lua): one line
// along the outer edge of each place (helmet with horns, armour with shoulder
// pads, the two boots, the gloves), nothing inside. A point is lit when the
// piece in front there is of a place (sagome_v) and the outside of that place's
// whole silhouette (sagome_u, the pieces of the place together, slits closed) is near: nearer
// than width.x always, and up to width.y where the drawing has its black line
// (sagome_i), so the whole outer line takes the color, thick or thin as it was
// drawn, and the lines inside stay black. Where the body covers a piece the
// line stops.
//   rect    the window rectangle the images cover (x, y, w, h in pixels)
//   width   x, y: the least and the most the line is wide, in window pixels;
//           z: how strong the glow is
//   c1-c4   each place's color (alpha 0: not lit)

out vec4 out_fragColor;

uniform mediump sampler2D sagome_u;
uniform mediump sampler2D sagome_v;
uniform mediump sampler2D sagome_i;
uniform mediump sampler2D sagome_g;

uniform fs_uniforms
{
    highp vec4 rect;
    mediump vec4 width;
    mediump vec4 c1;
    mediump vec4 c2;
    mediump vec4 c3;
    mediump vec4 c4;
};

const int N = 16;

void main()
{
    highp vec2 uv = (gl_FragCoord.xy - rect.xy) / rect.zw;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) discard;
    mediump vec3 v = texture(sagome_v, uv).rgb;
    mediump float v4 = min(v.r, min(v.g, v.b));
    mediump vec4 seen = vec4(v - v4, v4);
    // the glow: a soft light of the place's color just outside its pieces (sagome_g)
    // (fainter over the rest of the devil, so it does not wash the face or the flame)
    mediump vec4 i4 = texture(sagome_i, uv);
    mediump vec4 field = texture(sagome_g, uv);
    mediump vec4 halo = smoothstep(0.0, 0.5, field);
    mediump float any = seen.r + seen.g + seen.b + seen.a;
    halo = halo * halo * width.z * (1.0 - seen) * (1.0 - 0.65 * clamp(i4.a - any, 0.0, 1.0));
    mediump vec4 glow = c1 * halo.r + c2 * halo.g + c3 * halo.b + c4 * halo.a;
    if (any < 0.004) {
        out_fragColor = glow;
        return;
    }
    mediump float ink = i4.r / max(i4.a, 0.0001);

    // the least of the silhouette around (its slits already closed), near and far
    mediump vec4 near = vec4(1.0);
    mediump vec4 wide = vec4(1.0);
    for (int i = 0; i < N; i++) {
        highp float a = 6.2831853 * (float(i) + 0.5) / float(N);
        highp vec2 d = vec2(cos(a), sin(a)) / rect.zw;
        near = min(near, texture(sagome_u, uv + d * width.x));
        near = min(near, texture(sagome_u, uv + d * width.x * 0.5));
        wide = min(wide, texture(sagome_u, uv + d * width.y));
        wide = min(wide, texture(sagome_u, uv + d * (width.x + width.y) * 0.5));
    }
    wide = min(wide, near);
    mediump vec4 lit = max(smoothstep(0.0, 0.5, 1.0 - near), ink * smoothstep(0.35, 0.65, 1.0 - wide));
    mediump vec4 edge = seen * lit;
    mediump vec4 line = c1 * edge.r + c2 * edge.g + c3 * edge.b + c4 * edge.a;
    out_fragColor = line + glow * (1.0 - line.a);
}
