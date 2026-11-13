// The lights of the battle on the devil's pieces (Godot's 2D lights, taken to
// Defold, Sergio 13 Nov): the head flames and the explosions light the pieces
// from the side, as if each piece were a cushion. A gui node has a single
// texture, so there is no normal map: the normal comes from the piece's own
// alpha, read at 8 points a few screen pixels around the pixel (the nearer to
// the edge, the more it leans outward). The points are taken in screen
// directions (through the uv's derivatives), so rotation and mirroring of the
// piece come for free and the normal is already in screen axes.
// battle/lights.lua posts the lights; the render script (render/lit.render_script)
// gives them to every gui draw as light0..light5: x, y in screen pixels,
// z radius, w energy (0 = off), and the ambient. With no light near, only the ambient.

uniform fs_uniforms
{
    highp vec4 light0;
    highp vec4 light1;
    highp vec4 light2;
    highp vec4 light3;
    highp vec4 light4;
    highp vec4 light5;
    mediump vec4 light_ambient;  // rgb: what the pieces get with no light near; w: screen pixels per gui pixel
};

const mediump vec3 WARM = vec3(1.0, 0.62, 0.28);      // the flame's colour (as in Godot)
const mediump float REACH = 7.0;                       // how wide the cushion's edge is, in gui pixels
const mediump float LEAN = 2.5;                        // how much the edge leans

mediump float one_light(highp vec4 l, highp vec2 pos, mediump vec3 n)
{
    highp vec2 to = l.xy - pos;
    highp float r = max(l.z, 1.0);
    mediump float fall = 1.0 - clamp(length(to) / r, 0.0, 1.0);
    // a light a bit in front of the screen: flat parts get some, edges facing it more
    mediump vec3 dir = normalize(vec3(to, r * 0.12));
    return max(dot(n, dir), 0.0) * fall * fall * l.w;
}

// the piece's colour t (premultiplied) at uv, lit; pos in screen pixels
mediump vec4 lit(sampler2D tex, mediump vec4 t, highp vec2 uv, highp vec2 pos)
{
    // the derivatives first: they want every pixel of the block
    highp float reach = REACH * light_ambient.w;
    highp vec2 ux = dFdx(uv) * reach, uy = dFdy(uv) * reach;
    mediump float near = light0.w * step(distance(light0.xy, pos), light0.z)
                       + light1.w * step(distance(light1.xy, pos), light1.z)
                       + light2.w * step(distance(light2.xy, pos), light2.z)
                       + light3.w * step(distance(light3.xy, pos), light3.z)
                       + light4.w * step(distance(light4.xy, pos), light4.z)
                       + light5.w * step(distance(light5.xy, pos), light5.z);
    if (near <= 0.0 || t.a <= 0.0) return vec4(t.rgb * light_ambient.rgb, t.a);
    // where the piece is, around: the gradient of the alpha in screen directions
    mediump vec2 g = vec2(0.0);
    for (int k = 0; k < 8; k++) {
        mediump float a = 0.785398 * float(k);
        mediump vec2 d = vec2(cos(a), sin(a));
        g += d * texture(tex, uv + ux * d.x + uy * d.y, 1.0).a;
    }
    mediump vec3 n = normalize(vec3(-g * (LEAN / 4.0), 1.0));
    mediump float s = one_light(light0, pos, n) + one_light(light1, pos, n) + one_light(light2, pos, n)
                    + one_light(light3, pos, n) + one_light(light4, pos, n) + one_light(light5, pos, n);
    return vec4(t.rgb * (light_ambient.rgb + WARM * s), t.a);
}
