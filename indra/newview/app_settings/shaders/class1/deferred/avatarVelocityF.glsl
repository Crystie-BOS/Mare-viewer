/**
 * @file avatarVelocityF.glsl
 *
 * MARE: fragment shader for the skinned (rigged mesh) velocity pass (Phase 2 Step 4).
 *
 * Receives the current and previous clip-space positions from avatarVelocityV.glsl,
 * performs the perspective divide on both, and outputs the NDC velocity delta into
 * the RG16F velocity buffer.
 *
 * Identical in structure to dynamicVelocityF.glsl — the difference is entirely in
 * the vertex shader (which applies GPU skinning here vs. a rigid model transform).
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

in  vec4 vary_curr_clip;
in  vec4 vary_prev_clip;

out vec2 frag_vel;

void main()
{
    vec2 curr_ndc = vary_curr_clip.xy / vary_curr_clip.w;
    vec2 prev_ndc = vary_prev_clip.xy / vary_prev_clip.w;

    frag_vel = curr_ndc - prev_ndc;
}
