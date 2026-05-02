/**
 * mareCopyF.glsl  –  MARE Phase 3: trivial full-screen texture copy.
 *
 * Used as Pass 2 of the TAA pipeline to blit the new accumulated frame from
 * the upscaler's internal ping-pong buffer back into the main screen render
 * target so that the downstream post-processing chain sees the TAA result.
 */

uniform sampler2D colorMap;   // source (mAccumBuffer[outIdx])

in  vec2 vary_fragcoord;
out vec4 frag_color;

void main()
{
    frag_color = texture(colorMap, vary_fragcoord);
}
