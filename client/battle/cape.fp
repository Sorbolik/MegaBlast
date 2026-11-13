#version 140

// The cape (battle/scoria.lua, battle/cloth.lua): the whole drawing of the
// cape, bent along the simulated chain. The node is a square around the point
// where the cape is attached. The chain is smoothed into a curve (Catmull-Rom
// through its six points) and the curve is a strip of fifteen quads, like a mesh:
// each segment goes from one joint to the next, and at each joint the side
// edge is the bisector of the two segments (the miter), so neighbouring quads
// share it and the drawing bends without tearing. For each pixel, every quad
// it falls in gives where it is along the chain (s: height in the drawing) and
// to the side (d: width); later quads are drawn over earlier ones, as a mesh
// would. Four taps per sample, a quarter of a pixel around it, keep the thin
// outlines whole when the drawing is smaller on screen than in the image. At rest the chain hangs
// straight and the drawing is as it was drawn. The editor's Mantello panel uses
// this same file (tools/animazioni/prepara.py turns it into WebGL).
//
// Constants (node coordinates: -0.5 to 0.5 across the square, y up):
//   chain_a, chain_b, chain_c   the chain's six points (x, y, x, y)
//   frame   x, y: where it is attached in the drawing (0-1 from the left and the top);
//           z, w: the drawing's width and height over the node's side
// The node's color: b 1 normal, 0 all white (the hit flash), a how visible.
// The image is not in an atlas (scoria.lua loads it apart): its top left
// corner has a nearly transparent pixel that says which way is up (on the
// phone an image loaded apart can come upside down).

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

uniform fs_uniforms
{
    highp vec4 chain_a;
    highp vec4 chain_b;
    highp vec4 chain_c;
    highp vec4 frame;
};

float cross2(vec2 a, vec2 b) { return a.x * b.y - a.y * b.x; }

// the drawing at uv (x from the left, y from the top), averaged over a pixel
vec4 sample_at(vec2 uv, vec2 duv, float up)
{
    vec4 col = vec4(0.0);
    for (int k = 0; k < 4; k++) {
        vec2 o = vec2(k == 0 || k == 2 ? -duv.x : duv.x, k < 2 ? -duv.y : duv.y);
        vec2 q = uv + o;
        float inside = step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0);
        col += texture(texture_sampler, vec2(q.x, mix(1.0 - q.y, q.y, up))) * inside;
    }
    return col * 0.25;
}

void main()
{
    mediump float a = max(var_color.a, 0.0001);
    highp vec2 p = var_texcoord0 - 0.5;

    // the six points, with one more at each end to start and end the curve
    highp vec2 k[8];
    k[1] = chain_a.xy; k[2] = chain_a.zw;
    k[3] = chain_b.xy; k[4] = chain_b.zw;
    k[5] = chain_c.xy; k[6] = chain_c.zw;
    k[0] = 2.0 * k[1] - k[2];
    k[7] = 2.0 * k[6] - k[5];

    // the chain smoothed: a Catmull-Rom curve through the six points, three
    // quads for each segment, so the folds bend in a curve and not at a corner
    highp vec2 c[16];
    highp float total = 0.0;
    for (int j = 0; j < 5; j++) {
        highp vec2 p0 = k[j];
        highp vec2 p1 = k[j + 1];
        highp vec2 p2 = k[j + 2];
        highp vec2 p3 = k[j + 3];
        total += length(p2 - p1);
        for (int h = 0; h < 3; h++) {
            highp float u = float(h) / 3.0;
            c[j * 3 + h] = 0.5 * (2.0 * p1 + (p2 - p0) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
                                  + (3.0 * p1 - p0 - 3.0 * p2 + p3) * u * u * u);
        }
    }
    c[15] = k[6];

    // each segment's length and its side (to the right of the chain going down)
    highp vec2 n[15];
    highp float len[15];
    highp float curve = 0.0;
    for (int i = 0; i < 15; i++) {
        highp vec2 sg = c[i + 1] - c[i];
        len[i] = max(length(sg), 1e-5);
        curve += len[i];
        highp vec2 dir = sg / len[i];
        n[i] = vec2(-dir.y, dir.x);
    }
    // along the curve the drawing keeps the chain's length
    highp float stretch = total / curve;
    // the side edge at each joint: the miter, as long as it takes to keep the width
    highp vec2 m[16];
    m[0] = n[0];
    m[15] = n[14];
    for (int i = 1; i < 15; i++) m[i] = (n[i - 1] + n[i]) / max(1.0 + dot(n[i - 1], n[i]), 0.2);

    mediump float up = step(texture(texture_sampler, vec2(0.0005, 1.0 - 0.0005)).a,
                            texture(texture_sampler, vec2(0.0005, 0.0005)).a);
    // a quarter of a pixel, in the drawing
    highp vec2 duv = fwidth(p) / frame.zw * 0.25;

    // how far the drawing goes to the side of the chain, at most
    highp float wide = max(frame.x, 1.0 - frame.x) * frame.z + 0.01;
    mediump vec4 col = vec4(0.0);
    highp float run = 0.0;
    for (int i = 0; i < 15; i++) {
        // p = A + t e + d (Na + t f): find t (0-1 along the segment) and d
        highp vec2 A = c[i];
        highp vec2 e = c[i + 1] - A;
        highp vec2 Na = m[i];
        highp vec2 f = m[i + 1] - Na;
        highp vec2 q = p - A;
        // too far from this quad: skip it (most pixels are near one or two)
        highp float reach = 0.5 * len[i] + wide * max(length(Na), length(m[i + 1])) + (i == 0 || i == 14 ? 1.0 : 0.0);
        if (length(q - 0.5 * e) > reach) { run += len[i]; continue; }
        highp float k2 = -cross2(e, f);
        highp float k1 = cross2(q, f) - cross2(e, Na);
        highp float k0 = cross2(q, Na);
        // the first quad goes on above the attachment (the collar), the last past the end
        highp float lo = i == 0 ? -1.0 / len[i] : 0.0;
        highp float hi = i == 14 ? 1.0 + 1.0 / len[i] : 1.0;
        highp float t = -1e9;
        if (abs(k2) < 1e-7) {
            if (abs(k1) > 1e-9) t = -k0 / k1;
        } else {
            highp float disc = k1 * k1 - 4.0 * k2 * k0;
            if (disc >= 0.0) {
                highp float sq = sqrt(disc);
                highp float t1 = (-k1 - sq) / (2.0 * k2);
                highp float t2 = (-k1 + sq) / (2.0 * k2);
                t = (t1 >= lo && t1 < hi) ? t1 : t2;
            }
        }
        if (t >= lo && t < hi) {
            highp vec2 side = Na + t * f;
            highp float d = dot(q - t * e, side) / dot(side, side);
            highp float s = (run + t * len[i]) * stretch;
            highp vec2 uv = vec2(frame.x + d / frame.z, frame.y + s / frame.w);
            // only where the drawing is: the rest of the square reads nothing
            if (uv.x > -duv.x && uv.x < 1.0 + duv.x && uv.y > -duv.y && uv.y < 1.0 + duv.y) {
                mediump vec4 smp = sample_at(uv, duv, up);
                col = smp + col * (1.0 - smp.a);
            }
        }
        run += len[i];
    }

    mediump float white = 1.0 - var_color.b / a;
    out_fragColor = vec4(mix(col.rgb, vec3(col.a), white), col.a) * a;
}
