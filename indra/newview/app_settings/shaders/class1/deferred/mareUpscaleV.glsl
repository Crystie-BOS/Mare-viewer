/**
 * mareUpscaleV.glsl  –  MARE Phase 3: full-screen pass-through vertex shader.
 * Shared by the TAA accumulation pass and the TAA copy-back pass.
 */

in vec3 position;
out vec2 vary_fragcoord;   // [0,1] UV for texture sampling

void main()
{
    vec4 pos      = vec4(position.xyz, 1.0);
    gl_Position   = pos;
    vary_fragcoord = pos.xy * 0.5 + 0.5;
}
