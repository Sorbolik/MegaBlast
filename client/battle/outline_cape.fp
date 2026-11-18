#version 140

// The lit contour of the cape in the menus (menu/outline.lua): like
// battle/outline.fp, for the cape alone. The cape is behind the whole devil, so
// its line is drawn right above it and the body covers it by itself.
//   rect    the window rectangle the image covers (x, y, w, h in pixels)
//   width   x, y: the least and the most the line is wide, in window pixels
//   c1      the color (alpha 0: not lit)

out vec4 out_fragColor;

uniform mediump sampler2D sagome_c;

uniform fs_uniforms
{
    highp vec4 rect;
    mediump vec4 width;
    mediump vec4 c1;
};

const int N = 16;

void main()
{
    highp vec2 uv = (gl_FragCoord.xy - rect.xy) / rect.zw;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) discard;
    mediump vec4 c = texture(sagome_c, uv);
    mediump float seen = smoothstep(0.2, 0.8, c.a);
    if (seen < 0.004) discard;
    mediump float ink = 1.0 - smoothstep(0.14, 0.22, max(c.r, max(c.g, c.b)) / max(c.a, 0.0001));
    mediump float near = 1.0;
    mediump float wide = 1.0;
    for (int i = 0; i < N; i++) {
        highp float a = 6.2831853 * (float(i) + 0.5) / float(N);
        highp vec2 d = vec2(cos(a), sin(a)) / rect.zw;
        near = min(near, texture(sagome_c, uv + d * width.x).a);
        near = min(near, texture(sagome_c, uv + d * width.x * 0.5).a);
        wide = min(wide, texture(sagome_c, uv + d * width.y).a);
        wide = min(wide, texture(sagome_c, uv + d * (width.x + width.y) * 0.5).a);
    }
    wide = min(wide, near);
    out_fragColor = c1 * seen * smoothstep(0.0, 0.5, 1.0 - near);
}
