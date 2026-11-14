// The lights of the battle on the devil's pieces (Godot's 2D lights, taken to
// Defold, Sergio 13 Nov): the head flames and the explosions warm the pieces
// near them, fading smoothly with the distance. Only the distance counts, not
// the piece's shape: a relief from each piece's edges made blotches and showed
// where the pieces join (Sergio: «tutto macchiato»), so the light passes from a
// piece to the next without a seam.
// battle/lights.lua posts the lights; the render script (render/lit.render_script)
// gives them to every gui draw as light0..light5: x, y in screen pixels,
// z radius, w energy (0 = off), and the ambient.

uniform fs_uniforms
{
    highp vec4 light0;
    highp vec4 light1;
    highp vec4 light2;
    highp vec4 light3;
    highp vec4 light4;
    highp vec4 light5;
    mediump vec4 light_ambient;  // rgb: what the pieces get with no light near
};

const mediump vec3 WARM = vec3(1.0, 0.62, 0.28);      // the flame's colour (as in Godot)

mediump float one_light(highp vec4 l, highp vec2 pos)
{
    mediump float fall = 1.0 - clamp(distance(l.xy, pos) / max(l.z, 1.0), 0.0, 1.0);
    return fall * fall * l.w;
}

// the piece's colour t (premultiplied), lit; pos in screen pixels
mediump vec4 lit(mediump vec4 t, highp vec2 pos)
{
    mediump float s = one_light(light0, pos) + one_light(light1, pos) + one_light(light2, pos)
                    + one_light(light3, pos) + one_light(light4, pos) + one_light(light5, pos);
    return vec4(t.rgb * (light_ambient.rgb + WARM * s), t.a);
}
