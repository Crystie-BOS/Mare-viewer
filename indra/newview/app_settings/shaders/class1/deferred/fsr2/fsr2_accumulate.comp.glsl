/**
 * fsr2_accumulate.comp.glsl
 * MARE Phase 3 Step 3 — FSR 2 Pass 4: Temporal Accumulation
 *
 * Core temporal accumulation pass.  For each output pixel (at display
 * resolution) it:
 *   1. Fetches the current jittered colour at render resolution (colourSrc).
 *   2. Fetches the reprojected previous accumulated colour via the dilated
 *      motion vector (prevAccum).
 *   3. Computes a 3×3 YCoCg neighbourhood colour-box AABB to clamp history
 *      and suppress ghosting.
 *   4. Blends current and clamped history weighted by the lock confidence
 *      from Pass 3 and the motion-vector magnitude.
 *   5. Writes the accumulated result to the output image (display res).
 *
 * Inputs
 *   0  u_color        – current jittered frame   (RGBA16F, render res)
 *   1  u_prevAccum    – previous accumulated     (RGBA16F, display res)
 *   2  u_dilatedMV    – dilated NDC motion vec   (RG32F,   render res)
 *   3  u_lockStatus   – lock confidence [0..1]   (R8,      render res)
 *
 * Output
 *   4  u_output       – new accumulated frame    (RGBA16F image, display res)
 *
 * Uniforms
 *   u_renderSize   – (width, height) of render-resolution inputs
 *   u_displaySize  – (width, height) of display-resolution outputs
 *   u_jitter       – (jitterX, jitterY) sub-pixel offset applied this frame (UV space)
 *   u_cameraCut    – 1 = discard history (teleport / first frame)
 *   u_frameIndex   – monotonically increasing frame counter (for jitter phase)
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */
#version 430
layout(local_size_x = 8, local_size_y = 8) in;

layout(binding = 0) uniform sampler2D u_color;
layout(binding = 1) uniform sampler2D u_prevAccum;
layout(binding = 2) uniform sampler2D u_dilatedMV;
layout(binding = 3) uniform sampler2D u_lockStatus;

layout(rgba16f, binding = 4) writeonly uniform image2D u_output;

uniform ivec2 u_renderSize;
uniform ivec2 u_displaySize;
uniform vec2  u_jitter;       // UV-space jitter applied to current frame
uniform int   u_cameraCut;    // 1 = discard history
uniform int   u_frameIndex;

// ── YCoCg conversion helpers ──────────────────────────────────────────────────
vec3 RGBtoYCoCg(vec3 rgb)
{
    float Y  =  0.25 * rgb.r + 0.5 * rgb.g + 0.25 * rgb.b;
    float Co =  0.5  * rgb.r                - 0.5  * rgb.b;
    float Cg = -0.25 * rgb.r + 0.5 * rgb.g - 0.25 * rgb.b;
    return vec3(Y, Co, Cg);
}

vec3 YCoCgtoRGB(vec3 ycocg)
{
    float Y  = ycocg.x;
    float Co = ycocg.y;
    float Cg = ycocg.z;
    return vec3(Y + Co - Cg, Y + Cg, Y - Co - Cg);
}

// ── Neighbourhood AABB clamp ──────────────────────────────────────────────────
// Builds a tight AABB from the 3×3 neighbourhood in YCoCg space and clamps
// the history sample to it, suppressing ghosting.
vec3 clampHistory(vec2 uv, vec2 texel, vec3 histYCoCg)
{
    vec3 mn = vec3( 1e9);
    vec3 mx = vec3(-1e9);
    for (int dy = -1; dy <= 1; ++dy)
    {
        for (int dx = -1; dx <= 1; ++dx)
        {
            vec3 s = RGBtoYCoCg(texture(u_color, uv + vec2(dx, dy) * texel).rgb);
            mn = min(mn, s);
            mx = max(mx, s);
        }
    }
    return clamp(histYCoCg, mn, mx);
}

void main()
{
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(coord, u_displaySize))) return;

    // UV in display space → UV in render space (undo upscale, undo jitter)
    vec2 displayUV = (vec2(coord) + 0.5) / vec2(u_displaySize);

    // Scale from display UV to render UV
    vec2 scale     = vec2(u_renderSize) / vec2(u_displaySize);
    vec2 renderUV  = displayUV * scale - u_jitter;   // remove sub-pixel jitter

    vec2 texel     = 1.0 / vec2(u_renderSize);

    // ── Current-frame sample (render res, jitter already removed) ─────────────
    vec3 curr = texture(u_color, renderUV).rgb;

    // ── Motion vector → previous UV ──────────────────────────────────────────
    vec2 mv      = texture(u_dilatedMV, renderUV).rg;
    // MV is NDC delta; multiply by 0.5 to convert to UV delta
    vec2 prevUV  = displayUV - mv * 0.5;

    // ── Clamp history ─────────────────────────────────────────────────────────
    vec3 prevRGB = texture(u_prevAccum, prevUV).rgb;
    vec3 prevYC  = clampHistory(renderUV, texel, RGBtoYCoCg(prevRGB));
    vec3 prevClamped = YCoCgtoRGB(prevYC);

    // ── Blend factor ──────────────────────────────────────────────────────────
    float lock        = texture(u_lockStatus, renderUV).r;
    float mvMag       = length(mv);
    float motionDecay = 1.0 - smoothstep(0.0, 0.02, mvMag);

    // Base alpha from lock confidence.
    float alpha = mix(0.85, 0.97, lock * motionDecay);

    // Reduce history aggressively during fast camera/object motion to prevent
    // smearing.  Typical panning: 0.01–0.05 NDC/frame; fast pan: 0.05+ NDC/frame.
    // At full fade (mvMag >= 0.05), keep 15% history minimum so RCAS still has
    // something to sharpen and we don't get full temporal aliasing on fast pans.
    float fastFade = 1.0 - smoothstep(0.01, 0.05, mvMag) * 0.82;
    alpha *= fastFade;

    if (u_cameraCut != 0)
        alpha = 0.0;  // first frame or teleport — no history

    // ── Output ────────────────────────────────────────────────────────────────
    vec3 result = mix(curr, prevClamped, alpha);
    imageStore(u_output, coord, vec4(result, 1.0));
}
