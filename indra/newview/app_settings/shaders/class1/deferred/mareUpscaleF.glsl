/**
 * mareUpscaleF.glsl  –  MARE Phase 3: TAA temporal accumulation fragment shader.
 *
 * Algorithm overview
 *   1. Sample the current (jittered) frame colour at the current UV.
 *   2. Build a 3×3 neighbourhood AABB around the current pixel to bound what
 *      colours are "plausible" at this location this frame.
 *   3. Reproject the previous accumulated frame via the NDC motion vector:
 *        prevUV = uv − velocity * 0.5      (NDC delta → UV delta)
 *   4. Clamp the reprojected history sample to the neighbourhood AABB.
 *      This suppresses ghosting/smearing near disocclusion boundaries.
 *   5. Blend: result = mix(clampedHistory, current, alpha)
 *      where alpha = 0.1 for static pixels (90 % history → sharp AA)
 *                  = 0.5 for fast-moving pixels (50 % history → less ghosting).
 *
 * Inputs
 *   colorMap    (unit 0) – current jittered scene colour
 *   historyMap  (unit 1) – previous frame's accumulated result
 *   velocityMap (unit 2) – per-pixel NDC motion vector (RG16F)
 *
 * Uniforms
 *   jitter      – current-frame sub-pixel NDC jitter (from LLViewerCamera)
 *   cameraCut   – 1 on teleport or first frame; bypass history, output current
 */

uniform sampler2D colorMap;
uniform sampler2D historyMap;
uniform sampler2D velocityMap;

uniform vec2 jitter;      // current-frame sub-pixel NDC jitter
uniform int  cameraCut;   // 1 → discard history (teleport / first frame)

in  vec2 vary_fragcoord;
out vec4 frag_color;

void main()
{
    vec2 uv = vary_fragcoord;

    // ── current frame colour ─────────────────────────────────────────────────
    vec3 curr = texture(colorMap, uv).rgb;

    // ── camera-cut guard ─────────────────────────────────────────────────────
    // On first frame or after a teleport the history is stale / empty.
    // Output the raw current frame so the accumulation buffer is seeded
    // with a valid image for next frame.
    if (cameraCut != 0)
    {
        frag_color = vec4(curr, 1.0);
        return;
    }

    // ── 3×3 neighbourhood AABB ───────────────────────────────────────────────
    // Compute the min/max colour envelope of the 3×3 block of current-frame
    // pixels surrounding the current sample.  History is clamped to this box
    // to prevent stale colours from bleeding through (ghosting / smearing).
    vec2 texel  = 1.0 / vec2(textureSize(colorMap, 0));
    vec3 nMin = curr;
    vec3 nMax = curr;
    for (int dx = -1; dx <= 1; ++dx)
    {
        for (int dy = -1; dy <= 1; ++dy)
        {
            if (dx == 0 && dy == 0) continue;
            vec3 s = texture(colorMap, uv + vec2(dx, dy) * texel).rgb;
            nMin = min(nMin, s);
            nMax = max(nMax, s);
        }
    }

    // ── motion-vector reprojection ───────────────────────────────────────────
    // velocityMap stores the NDC delta: current_NDC − previous_NDC.
    // Converting NDC delta to UV delta requires a factor of 0.5.
    vec2 vel    = texture(velocityMap, uv).rg;
    vec2 prevUV = uv - vel * 0.5;

    // Pixels whose reprojection falls outside the screen have no valid history.
    if (any(lessThan(prevUV, vec2(0.0))) || any(greaterThan(prevUV, vec2(1.0))))
    {
        frag_color = vec4(curr, 1.0);
        return;
    }

    // ── history sample + AABB clamp ──────────────────────────────────────────
    vec3 hist = texture(historyMap, prevUV).rgb;

    // Minimal fixed expansion (±0.01) to tolerate the ±0.25 px sub-pixel jitter
    // shifting a smooth colour just outside the strict neighbourhood boundary.
    // Kept deliberately tight so occlusion-boundary ghosting is still suppressed
    // when the camera moves.  A range-proportional slack caused visible ghost
    // trails on fast camera pans.
    hist = clamp(hist, nMin - 0.01, nMax + 0.01);

    // ── adaptive blend ───────────────────────────────────────────────────────
    // Static pixels  (vel ≈ 0) : 95 % history → sub-pixel jitter averages away
    //                             in a couple of frames, output is stable.
    // Fast pixels (vel large)  : 50 % history → stale / displaced history is
    //                             cleared in 2–3 frames, suppressing ghost trails.
    float velLen    = length(vel);
    float blendCurr = mix(0.05, 0.5, clamp(velLen * 20.0, 0.0, 1.0));

    vec3 result = mix(hist, curr, blendCurr);
    frag_color  = vec4(result, 1.0);
}
