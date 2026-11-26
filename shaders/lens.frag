#version 440
// Folyékony üveg lencse: a mögötte lévő tartalom (src) elmosva, a szélek felé erősödő
// fénytöréssel és enyhe színszórással, peremfénnyel és belső csillanással.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;        // a lencse mérete (px)
    float radius;     // sarokkerekítés (px)
    float pad;        // a forráskép ennyivel nagyobb minden oldalon (px)
    float blur;       // elmosás sugara (px)
    float refraction; // fénytörés erőssége (0..1)
    float dark;       // 1 = sötét üveg, 0 = világos
    float tintAlpha;  // a dér erőssége
    vec4 tint;        // dér színe
    float press;      // lenyomás (0..1): kicsit erősebb fény
};
layout(binding = 1) uniform sampler2D src;

float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 sampleBlur(vec2 uv, vec2 texel, float r) {
    // 13 mintavétel két gyűrűn + középen (a forrás már kicsinyítve készül, ez tovább simít)
    vec4 acc = texture(src, uv) * 2.0;
    float w = 2.0;
    for (int i = 0; i < 6; i++) {
        float a = float(i) * 1.0471976;
        vec2 d = vec2(cos(a), sin(a));
        acc += texture(src, uv + d * texel * r * 0.5);
        acc += texture(src, uv + d.yx * vec2(1.0, -1.0) * texel * r) * 0.8;
        w += 1.8;
    }
    return acc / w;
}

void main() {
    vec2 p = qt_TexCoord0 * size;
    vec2 c = size * 0.5;
    float rr = min(radius, min(size.x, size.y) * 0.5);
    float d = sdRoundRect(p - c, c, rr);
    float aa = clamp(0.5 - d, 0.0, 1.0);
    if (aa <= 0.0) { fragColor = vec4(0.0); return; }

    // a szélhez közeledve erősödő hajlítás befelé
    float inside = clamp(-d / max(rr, 1.0), 0.0, 1.0);
    float edge = pow(1.0 - inside, 2.4);
    vec2 q = p - c;
    vec2 nearest = clamp(q, -c + vec2(rr), c - vec2(rr));
    vec2 n = q - nearest;
    float nl = length(n);
    n = nl > 0.001 ? n / nl : vec2(0.0, sign(q.y + 0.0001));
    float bend = edge * refraction * min(size.y, 90.0) * 0.55;

    vec2 full = size + vec2(2.0 * pad);
    vec2 texel = 1.0 / full;
    vec2 base = (p + vec2(pad)) / full;
    vec2 off = -n * bend * texel;

    // enyhe színszórás a peremen
    // (a forrás előszorzott alfájú: az átlátszó ablakon át az asztal elmosása látszik)
    float r = sampleBlur(base + off * 1.06, texel, blur).r;
    vec4 gs = sampleBlur(base + off, texel, blur);
    float b = sampleBlur(base + off * 0.94, texel, blur).b;
    float a = max(gs.a, 0.001);
    vec3 col = vec3(r, gs.g, b) / a;   // egyenes szín

    // dér
    col = mix(col, tint.rgb, tintAlpha);
    float outA = clamp(mix(gs.a, 1.0, tintAlpha * 0.9) + 0.06, 0.0, 1.0);
    // fényesség kicsit fel (vagy le sötét üvegnél)
    col = mix(col * (1.0 + 0.10 * (1.0 - dark)), col * 0.92, dark * 0.3);

    // peremfény: felül erősebb
    float rim = smoothstep(2.2, 0.0, -d) * (0.55 + 0.45 * (1.0 - qt_TexCoord0.y));
    float inner = smoothstep(9.0, 0.0, -d) * 0.10;
    // belső csillanás a felső részen
    float gloss = smoothstep(0.55, 0.0, qt_TexCoord0.y) * 0.07 * (1.0 + press);
    col += vec3(rim * (0.38 + 0.2 * press) + inner + gloss);

    col = clamp(col, 0.0, 1.0);
    float fa = clamp(outA + rim * 0.5, 0.0, 1.0);
    fragColor = vec4(col * fa, fa) * aa * qt_Opacity;
}
