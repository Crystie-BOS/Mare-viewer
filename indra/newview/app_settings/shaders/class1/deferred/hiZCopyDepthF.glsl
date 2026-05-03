/**
 * @file class1/deferred/hiZCopyDepthF.glsl
 *
 * MARE: Copy scene depth to mip 0 of the Hi-Z pyramid (R32F color output).
 * Stores raw [0,1] NDC depth values so the reduce pass works without
 * any coordinate conversion.
 *
 * $LicenseInfo:firstyear=2026&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

/*[EXTRA_CODE_HERE]*/

out float frag_color;

in vec2 vary_fragcoord;

uniform sampler2D depthMap;

void main()
{
    frag_color = texture(depthMap, vary_fragcoord).r;
}
