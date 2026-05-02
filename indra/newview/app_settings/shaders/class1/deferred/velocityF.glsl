/**
 * @file velocityF.glsl
 *
 * MARE: deferred full-screen fragment shader that writes a per-pixel
 * screen-space velocity (motion vector) into the RG16F velocity buffer.
 *
 * Algorithm:
 *   1. Sample hardware depth at the current UV.
 *   2. Reconstruct NDC position from UV + depth.
 *   3. Unproject to view-space via inv_proj  (auto-uploaded by LLRender).
 *   4. Unproject to world-space via inv_modelview (auto-uploaded by LLRender).
 *   5. Reproject into previous-frame clip-space via prev_vp (set each frame
 *      by the velocity dispatch in pipeline.cpp from LLViewerCamera::getPrevViewProj()).
 *   6. Output NDC delta (current - previous) as the 2-channel velocity vector.
 *
 * The output is consumed by the TAA resolve / FSR 2 upscaler in Phase 3.
 * Sky pixels (depth == 1.0) receive zero velocity.
 *
 * Phase 2 — motion vectors for TAA / FSR 2 upscaler.
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

uniform sampler2D depthMap;     // bound by bindDeferredShader via DEFERRED_DEPTH
uniform mat4      inv_proj;     // auto-uploaded by LLRender (INVERSE_PROJECTION_MATRIX)
uniform mat4      inv_modelview;// auto-uploaded by LLRender (INVERSE_MODELVIEW_MATRIX)
uniform mat4      prev_vp;      // MARE: previous-frame view-projection (set per-frame)

in  vec2 vary_fragcoord;
out vec2 frag_vel;

void main()
{
    float depth = texture(depthMap, vary_fragcoord).r;

    // Sky / far-plane pixels: zero velocity, skip reprojection
    if (depth >= 1.0)
    {
        frag_vel = vec2(0.0);
        return;
    }

    // --- Reconstruct current NDC position ---
    // depth buffer [0,1] → NDC z [-1,1]
    vec4 ndc_curr = vec4(vary_fragcoord * 2.0 - 1.0,
                         depth          * 2.0 - 1.0,
                         1.0);

    // --- Unproject: NDC → view-space ---
    vec4 view_pos = inv_proj * ndc_curr;
    view_pos /= view_pos.w;

    // --- Unproject: view-space → world-space ---
    vec4 world_pos = inv_modelview * view_pos;

    // --- Reproject: world-space → previous-frame clip-space ---
    vec4 prev_clip = prev_vp * world_pos;
    vec2 prev_ndc  = prev_clip.xy / prev_clip.w;

    // Output: signed NDC delta, range approximately [-2, 2]
    // TAA/FSR 2 resolve will use this to look up the previous frame's colour.
    frag_vel = ndc_curr.xy - prev_ndc;
}
