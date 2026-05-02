/**
 * fsr2_lock.comp.glsl
 * MARE Phase 3 Step 3 — FSR 2 Pass 3: Shading Change Detection / Lock
 *
 * Detects "stable" pixels where the scene colour and depth have not changed
 * significantly between the current and previous frames.  Stable pixels
 * receive a high lock confidence value; unstable pixels (new geometry, large
 * shading change, disocclusion) receive zero confidence.
 *
 * A high confidence causes the accumulation pass to blend more history
 * (better temporal stability).  Zero confidence forces the current frame to
 * dominate (no ghosting on moving or newly-revealed surfaces).
 *
 * Inputs
 *   0  u_color          – current-frame HDR colour   (RGBA16F)
 *   1  u_prevColor      – previous accumulated colour (RGBA16F)
 *   2  u_dilatedDepth   – dilated current depth       (R32F image from Pass 1)
 *   3  u_reconPrevDepth – reconstructed previous depth (R32F image from Pass 2)
 *
 * Output
 *   4  u_lockStatus – lock confidence [0..1]          (R8 image)
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */
#version 430
layout(local_size_x = 8, local_size_y = 8) in;

layout(binding = 0) uniform sampler2D u_color;
layout(binding = 1) uniform sampler2D u_prevColor;
layout(binding = 2) uniform sampler2D u_dilatedDepth;
layout(binding = 3) uniform sampler2D u_reconPrevDepth;

layout(r8, binding = 4) writeonly uniform image2D u_lockStatus;

uniform ivec2 u_renderSize;

// BT.709 perceptual luma
float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

void main()
{
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(coord, u_renderSize))) return;

    vec2 uv = (vec2(coord) + 0.5) / vec2(u_renderSize);

    // ── Depth dis-occlusion check ─────────────────────────────────────────────
    float currD = texture(u_dilatedDepth,   uv).r;
    float prevD = texture(u_reconPrevDepth, uv).r;

    // Large depth difference → newly revealed surface → unlock
    float depthDelta = abs(currD - prevD);
    float depthLock  = 1.0 - smoothstep(0.001, 0.05, depthDelta);

    // ── Luminance change check ────────────────────────────────────────────────
    float lumCurr = luma(texture(u_color,     uv).rgb);
    float lumPrev = luma(texture(u_prevColor, uv).rgb);
    float lumDiff = abs(lumCurr - lumPrev) / (max(lumCurr, lumPrev) + 0.01);
    float lumLock = 1.0 - smoothstep(0.05, 0.3, lumDiff);

    float confidence = depthLock * lumLock;
    imageStore(u_lockStatus, coord, vec4(confidence, 0.0, 0.0, 0.0));
}
