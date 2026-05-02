/**
 * @file velocityV.glsl
 *
 * MARE: full-screen pass-through vertex shader for the velocity/motion-vector
 * buffer.  Identical to blurLightV.glsl in structure — position comes in as
 * a full-screen triangle and is forwarded straight to clip space.
 *
 * Phase 2 — motion vectors for TAA / FSR 2 upscaler.
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

in vec3 position;

out vec2 vary_fragcoord;

void main()
{
    vec4 pos    = vec4(position.xyz, 1.0);
    gl_Position = pos;
    vary_fragcoord = (pos.xy * 0.5 + 0.5);
}
