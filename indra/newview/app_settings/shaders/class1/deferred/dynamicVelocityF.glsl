/**
 * @file dynamicVelocityF.glsl
 *
 * MARE: fragment shader for the per-object dynamic velocity pass (Phase 2 Step 3).
 *
 * Receives the current and previous clip-space positions from the vertex shader,
 * performs the perspective divide on both, and outputs the NDC velocity delta into
 * the RG16F velocity buffer.
 *
 * The depth test (GL_LEQUAL, no writes) in the dispatch ensures that only
 * visible pixels of the moving drawable overwrite the camera-reprojection
 * velocity written by the static velocity pass (velocityF.glsl).
 *
 * Sky pixels are never reached because the drawable geometry lies in front of
 * the far plane.
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

in  vec4 vary_curr_clip;   // current-frame clip position (from dynamicVelocityV)
in  vec4 vary_prev_clip;   // previous-frame clip position (from dynamicVelocityV)

out vec2 frag_vel;

void main()
{
    // Perspective divide → NDC xy
    vec2 curr_ndc = vary_curr_clip.xy / vary_curr_clip.w;
    vec2 prev_ndc = vary_prev_clip.xy / vary_prev_clip.w;

    // Output signed NDC delta; same convention as velocityF.glsl
    frag_vel = curr_ndc - prev_ndc;
}
