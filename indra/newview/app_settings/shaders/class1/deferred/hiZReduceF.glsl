/**
 * @file class1/deferred/hiZReduceF.glsl
 *
 * MARE: Min-reduce pass for the Hi-Z depth pyramid (R32F color output).
 * Each dispatch covers one mip level: samples a 2x2 block from the previous
 * mip and writes the minimum (closest to camera in NDC = smallest value).
 *
 * $LicenseInfo:firstyear=2026&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

/*[EXTRA_CODE_HERE]*/

out float frag_color;

in vec2 vary_fragcoord;

uniform sampler2D hiZMap;
uniform int srcLevel;

void main()
{
    // Destination texel size at this mip level is implicit from gl_FragCoord.
    // We fetch 4 texels from srcLevel using texelFetch so we stay level-precise.
    ivec2 src = ivec2(gl_FragCoord.xy) * 2;

    float d0 = texelFetch(hiZMap, src,                  srcLevel).r;
    float d1 = texelFetch(hiZMap, src + ivec2(1, 0),    srcLevel).r;
    float d2 = texelFetch(hiZMap, src + ivec2(0, 1),    srcLevel).r;
    float d3 = texelFetch(hiZMap, src + ivec2(1, 1),    srcLevel).r;

    // Min = closest surface (smallest NDC depth value).
    frag_color = min(min(d0, d1), min(d2, d3));
}
