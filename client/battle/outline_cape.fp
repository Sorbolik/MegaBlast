#version 140

// The lit contour of the cape in the menus (menu/outline.lua): like
// battle/outline.fp, for the cape alone. The cape is behind the whole devil, so
// its line is drawn right above it and the body covers it by itself.
//   rect    the window rectangle the image covers (x, y, w, h in pixels)
//   width   x: the line's width in window pixels
//   c1      the color (alpha 0: not lit)

out vec4 out_fragColor;

uniform mediump sampler2D sagome_c;

uniform fs_uniforms
{
    highp vec4 rect;
    mediump vec4 width;
    mediump vec4 c1;
};

const int N = 24;

void main()
{
    highp vec2 uv = (gl_FragCoord.xy - rect.xy) / rect.zw;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) discard;
    mediump float seen = texture(sagome_c, uv).a;
    if (seen < 0.004) discard;
    mediump float least = 1.0;
    for (int i = 0; i < N; i++) {
        highp float a = 6.2831853 * (float(i) + 0.5) / float(N);
        highp vec2 d = vec2(cos(a), sin(a)) / rect.zw * width.x;
        least = min(least, texture(sagome_c, uv + d).a);
        least = min(least, texture(sagome_c, uv + d * 0.5).a);
    }
    out_fragColor = c1 * seen * smoothstep(0.0, 0.5, 1.0 - least);
}
