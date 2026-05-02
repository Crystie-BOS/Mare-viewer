/**
 * fsr2_depth_clip.comp.glsl
 * MARE Phase 3 Step 3 — FSR 2 Pass 1: Depth Clip / Dilate
 *
 * Dilates the current-frame depth and motion-vector buffers by 3x3
 * neighbourhood maximum (depth) and nearest-to-camera sample (motion).
 * The dilated outputs feed the Reconstruct Previous Depth pass.
 *
 * Inputs  (image units, read-only)
 *   0  u_depth       – current-frame depth   (R32F)
 *   1  u_motionVec   – current-frame NDC MV  (RG32F, same encoding as mVelocityBuffer)
 *
 * Outputs (image units, write-only)
 *   2  u_dilatedDepth – dilated depth         (R32F)
 *   3  u_dilatedMV    – dilated motion vector (RG32F)
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */
#version 430
layout(local_size_x = 8, local_size_y = 8) in;

layout(binding = 0) uniform sampler2D  u_depth;
layout(binding = 1) uniform sampler2D  u_motionVec;

layout(rgba32f, binding = 2) writeonly uniform image2D u_dilatedDepth;
layout(rgba32f, binding = 3) writeonly uniform image2D u_dilatedMV;

uniform ivec2 u_renderSize;

void main()
{
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(coord, u_renderSize))) return;

    vec2 uv = (vec2(coord) + 0.5) / vec2(u_renderSize);
    vec2 texel = 1.0 / vec2(u_renderSize);

    // ── 3×3 neighbourhood search ──────────────────────────────────────────────
    // Pick the sample closest to the camera (minimum depth in [0,1] NDC where
    // 0 = near, 1 = far) — this is the most likely foreground object.
    float minDepth = 1.0;
    vec2  bestMV   = vec2(0.0);

    for (int dy = -1; dy <= 1; ++dy)
    {
        for (int dx = -1; dx <= 1; ++dx)
        {
            vec2 suv = uv + vec2(dx, dy) * texel;
            float d = texture(u_depth, suv).r;
            if (d < minDepth)
            {
                minDepth = d;
                bestMV   = texture(u_motionVec, suv).rg;
            }
        }
    }

    imageStore(u_dilatedDepth, coord, vec4(minDepth, 0.0, 0.0, 0.0));
    imageStore(u_dilatedMV,    coord, vec4(bestMV,   0.0, 0.0));
}
