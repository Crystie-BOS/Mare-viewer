/**
 * fsr2_reconstruct_prev_depth.comp.glsl
 * MARE Phase 3 Step 3 — FSR 2 Pass 2: Reconstruct Previous Depth
 *
 * Uses the dilated motion vector to look up where each pixel was in the
 * previous frame and fetches its reprojected depth.  The result is the
 * "previous depth" buffer used by the accumulation pass to detect
 * dis-occlusions.
 *
 * Inputs  (samplers)
 *   0  u_dilatedMV    – dilated motion vector from Pass 1  (RG32F)
 *   1  u_prevDepth    – previous-frame depth               (R32F)
 *
 * Output  (image unit)
 *   2  u_reconPrevDepth – reconstructed previous depth     (R32F image)
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */
#version 430
layout(local_size_x = 8, local_size_y = 8) in;

layout(binding = 0) uniform sampler2D u_dilatedMV;
layout(binding = 1) uniform sampler2D u_prevDepth;

layout(r32f, binding = 2) writeonly uniform image2D u_reconPrevDepth;

uniform ivec2 u_renderSize;

void main()
{
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(coord, u_renderSize))) return;

    vec2 uv = (vec2(coord) + 0.5) / vec2(u_renderSize);

    // Reproject: current UV − motion vector → previous UV
    vec2 mv      = texture(u_dilatedMV, uv).rg;
    vec2 prevUV  = uv - mv * 0.5;  // MV is NDC delta; 0.5 converts to UV delta

    float prevD  = texture(u_prevDepth, prevUV).r;
    imageStore(u_reconPrevDepth, coord, vec4(prevD, 0.0, 0.0, 0.0));
}
