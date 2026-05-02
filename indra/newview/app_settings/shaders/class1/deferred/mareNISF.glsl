/**
 * mareNISF.glsl  –  MARE Phase 3 Step 2: NIS-inspired adaptive sharpening.
 *
 * Algorithm overview
 *   1. Sample centre (C) and 8 neighbours (N S E W NE NW SE SW).
 *   2. Compute BT.709 luma for each sample.
 *   3. Neighbourhood luma range [lMin, lMax] defines local contrast.
 *   4. Adaptive sharpening weight:
 *        w = sharpenStrength * min(lC, 1.0 - lC) / (lMax - lMin + epsilon)
 *        w = clamp(w, 0.0, 0.5)
 *      High contrast  -> small w  (avoids haloing on already sharp edges).
 *      Dark/bright extremes -> small w  (perceptual protection).
 *   5. 8-neighbour uniform average (weight 1/8 each).
 *   6. Unsharp mask:   result = C + (C - avg8) * w
 *   7. Soft-clamp result luma to [lMin, lMax] to suppress halo artefacts.
 *
 * Uniforms
 *   colorMap        – input colour texture (post-TAA or raw scene)
 *   sharpenStrength – [0..1], driven by RenderNISSharpenStrength
 */

uniform sampler2D colorMap;
uniform float     sharpenStrength;

in  vec2 vary_fragcoord;
out vec4 frag_color;

// BT.709 perceptual luminance
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

void main()
{
    vec2 uv    = vary_fragcoord;
    vec2 texel = 1.0 / vec2(textureSize(colorMap, 0));

    // ── 3x3 neighbourhood samples ─────────────────────────────────────────────
    vec3 C  = texture(colorMap, uv).rgb;
    vec3 N  = texture(colorMap, uv + vec2( 0.0,  1.0) * texel).rgb;
    vec3 S  = texture(colorMap, uv + vec2( 0.0, -1.0) * texel).rgb;
    vec3 E  = texture(colorMap, uv + vec2( 1.0,  0.0) * texel).rgb;
    vec3 W  = texture(colorMap, uv + vec2(-1.0,  0.0) * texel).rgb;
    vec3 NE = texture(colorMap, uv + vec2( 1.0,  1.0) * texel).rgb;
    vec3 NW = texture(colorMap, uv + vec2(-1.0,  1.0) * texel).rgb;
    vec3 SE = texture(colorMap, uv + vec2( 1.0, -1.0) * texel).rgb;
    vec3 SW = texture(colorMap, uv + vec2(-1.0, -1.0) * texel).rgb;

    // ── neighbourhood luma range ──────────────────────────────────────────────
    float lC = luma(C);

    float lMin = min(lC, min(min(luma(N), luma(S)), min(luma(E), luma(W))));
    lMin = min(lMin, min(min(luma(NE), luma(NW)), min(luma(SE), luma(SW))));

    float lMax = max(lC, max(max(luma(N), luma(S)), max(luma(E), luma(W))));
    lMax = max(lMax, max(max(luma(NE), luma(NW)), max(luma(SE), luma(SW))));

    // ── adaptive sharpening weight ────────────────────────────────────────────
    float contrast = lMax - lMin + 1e-6;
    float w = sharpenStrength * min(lC, 1.0 - lC) / contrast;
    w = clamp(w, 0.0, 0.5);

    // ── 8-neighbour uniform average ───────────────────────────────────────────
    vec3 avg8 = (N + S + E + W + NE + NW + SE + SW) * 0.125;

    // ── unsharp mask ──────────────────────────────────────────────────────────
    vec3 result = C + (C - avg8) * w;

    // ── soft luma clamp (suppress halos) ─────────────────────────────────────
    float lR = luma(result);
    if (lR > 1e-6)
        result *= clamp(lR, lMin, lMax) / lR;

    frag_color = vec4(result, 1.0);
}
