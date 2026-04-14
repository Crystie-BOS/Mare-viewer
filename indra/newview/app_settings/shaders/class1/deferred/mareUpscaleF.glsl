/**
 * mareUpscaleF.glsl  –  MARE Phase 3: TAA temporal accumulation fragment shader.
 * v1.1 — variance clamping, HDR-aware blending, improved ghost suppression.
 *
 * Algorithm overview
 *   1. Sample the current (jittered) frame colour at uv.
 *   2. Build a 3×3 neighbourhood AABB AND compute mean/variance over that
 *      window.  Use the intersection of the AABB and the variance box
 *      (mean ± γ·σ) as the clamping bounds — this is tighter than pure AABB
 *      near edges yet looser in flat regions, greatly reducing ghosting while
 *      keeping stable AA in static areas.
 *   3. Reproject the previous accumulated frame via the NDC motion vector:
 *        prevUV = uv − velocity * 0.5      (NDC delta → UV delta)
 *   4. Clamp the history sample to the combined bounds (step 2).
 *   5. Blend: result = mix(clampedHistory, current, alpha)
 *      α = 0.10 for static pixels  (10 % current → stable sub-pixel AA)
 *      α = 0.40 for fast pixels    (40 % current → ghosts clear in ~2 frames)
 *
 * Inputs
 *   colorMap    (unit 0) – current jittered scene colour (linear HDR)
 *   historyMap  (unit 1) – previous frame accumulated result (linear HDR)
 *   velocityMap (unit 2) – per-pixel NDC motion vector (RG16F)
 *
 * Uniforms
 *   cameraCut   – 1 on teleport / first frame; bypass history, seed with current
 */

uniform sampler2D colorMap;
uniform sampler2D historyMap;
uniform sampler2D velocityMap;

uniform vec2 jitter;      // not used in frag — jitter is applied to projection matrix
uniform int  cameraCut;   // 1 → discard history (teleport / first frame)

in  vec2 vary_fragcoord;
out vec4 frag_color;

// ── BT.709 luminance ────────────────────────────────────────────────────────
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// ── Weighted Reinhard tonemap (used during blending only) ───────────────────
// Compresses HDR values so AABB / variance clamping is meaningful at all
// luminance levels.  Inverse is applied before storing back to the buffer.
vec3 tmap(vec3 c)    { return c / (1.0 + luma(c)); }
vec3 tmapInv(vec3 c) { return c / max(1.0 - luma(c), 1e-4); }

void main()
{
    vec2 uv = vary_fragcoord;

    // ── current frame colour (tonemapped for processing) ─────────────────────
    vec3 currLinear = texture(colorMap, uv).rgb;
    vec3 curr = tmap(currLinear);

    // ── camera-cut guard ─────────────────────────────────────────────────────
    // On first frame or after a teleport the history is stale / empty.
    // Seed the accumulation buffer with the current frame.
    if (cameraCut != 0)
    {
        frag_color = vec4(currLinear, 1.0);
        return;
    }

    // ── 3×3 neighbourhood — AABB + mean + variance ───────────────────────────
    vec2 texel = 1.0 / vec2(textureSize(colorMap, 0));

    vec3 nMin = curr;
    vec3 nMax = curr;
    vec3 m1   = curr;        // running sum  (for mean)
    vec3 m2   = curr * curr; // running sum² (for variance)

    for (int dx = -1; dx <= 1; ++dx)
    {
        for (int dy = -1; dy <= 1; ++dy)
        {
            if (dx == 0 && dy == 0) continue;
            vec3 s = tmap(texture(colorMap, uv + vec2(dx, dy) * texel).rgb);
            nMin  = min(nMin, s);
            nMax  = max(nMax, s);
            m1   += s;
            m2   += s * s;
        }
    }

    // Variance clamping bounds: mean ± γ·σ  (γ = 1.25 balances AA vs ghosting)
    vec3 mu    = m1 / 9.0;
    vec3 sigma = sqrt(max(m2 / 9.0 - mu * mu, vec3(0.0)));
    const float gamma = 1.25;
    vec3 vMin  = mu - gamma * sigma;
    vec3 vMax  = mu + gamma * sigma;

    // Combined bounds = intersection of AABB and variance box.
    // Tighter near edges (where AABB is already tight), looser in flat regions.
    vec3 cMin = max(nMin, vMin);
    vec3 cMax = min(nMax, vMax);

    // ── motion-vector reprojection ───────────────────────────────────────────
    vec2 vel    = texture(velocityMap, uv).rg;
    vec2 prevUV = uv - vel * 0.5;   // NDC delta → UV delta (÷2)

    // No valid history for off-screen reprojections.
    if (any(lessThan(prevUV, vec2(0.0))) || any(greaterThan(prevUV, vec2(1.0))))
    {
        frag_color = vec4(currLinear, 1.0);
        return;
    }

    // ── history sample + variance clamp ──────────────────────────────────────
    vec3 hist = tmap(texture(historyMap, prevUV).rgb);
    hist = clamp(hist, cMin, cMax);

    // ── adaptive blend ───────────────────────────────────────────────────────
    // Static pixels (vel ≈ 0) : 10 % current → jitter averages in ~7 frames.
    // Fast pixels  (vel large) : 40 % current → ghosts clear in ~2 frames.
    // Velocity threshold: 0.05 NDC ≈ 5 % of screen width triggers full motion blend.
    float velLen    = length(vel);
    float blendCurr = mix(0.10, 0.40, clamp(velLen * 20.0, 0.0, 1.0));

    vec3 result = mix(hist, curr, blendCurr);

    // Store back in linear HDR (inverse tonemap).
    frag_color = vec4(tmapInv(result), 1.0);
}
