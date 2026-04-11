/**
 * fsr2_rcas.comp.glsl
 * MARE Phase 3 Step 3 — FSR 2 Pass 5: RCAS (Robust Contrast-Adaptive Sharpening)
 *
 * Post-accumulation sharpening pass.  Runs at display resolution on the
 * temporal accumulation output.  Applies a neighbourhood-contrast-adaptive
 * unsharp mask that boosts fine detail without ringing on already-sharp edges.
 *
 * The RCAS algorithm:
 *   1. Sample centre C and 4 cross neighbours (N, S, E, W).
 *   2. Find neighbourhood min/max luma.
 *   3. Compute a sharpening weight inversely proportional to local contrast
 *      (high contrast → gentle sharpening to avoid haloing).
 *   4. Output = C + (C - avg4) * weight.
 *   5. Clamp output luma to [minLuma, maxLuma] to suppress ringing.
 *
 * Inputs
 *   0  u_accum   – accumulated colour from Pass 4  (RGBA16F, display res)
 *
 * Output
 *   1  u_output  – sharpened colour                (RGBA16F image, display res)
 *
 * Uniform
 *   u_sharpness  – [0..1] sharpening strength (mapped to weight multiplier)
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */
#version 430
layout(local_size_x = 8, local_size_y = 8) in;

layout(binding = 0) uniform sampler2D u_accum;

layout(rgba16f, binding = 1) writeonly uniform image2D u_output;

uniform ivec2 u_displaySize;
uniform float u_sharpness;    // [0..1]

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

void main()
{
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    if (any(greaterThanEqual(coord, u_displaySize))) return;

    vec2 uv    = (vec2(coord) + 0.5) / vec2(u_displaySize);
    vec2 texel = 1.0 / vec2(u_displaySize);

    vec3 C = texture(u_accum, uv).rgb;
    vec3 N = texture(u_accum, uv + vec2( 0.0,  1.0) * texel).rgb;
    vec3 S = texture(u_accum, uv + vec2( 0.0, -1.0) * texel).rgb;
    vec3 E = texture(u_accum, uv + vec2( 1.0,  0.0) * texel).rgb;
    vec3 W = texture(u_accum, uv + vec2(-1.0,  0.0) * texel).rgb;

    float lC = luma(C);
    float lN = luma(N);
    float lS = luma(S);
    float lE = luma(E);
    float lW = luma(W);

    float lMin = min(lC, min(min(lN, lS), min(lE, lW)));
    float lMax = max(lC, max(max(lN, lS), max(lE, lW)));

    // Contrast-adaptive weight: weaker near high-contrast edges
    float contrast = lMax - lMin + 1e-6;
    float weight   = u_sharpness * min(lC, 1.0 - lC) / contrast;
    weight = clamp(weight, 0.0, 0.5);

    vec3 avg4  = (N + S + E + W) * 0.25;
    vec3 result = C + (C - avg4) * weight;

    // Soft luma clamp to suppress ringing
    float lR = luma(result);
    if (lR > 1e-6)
        result *= clamp(lR, lMin, lMax) / lR;

    imageStore(u_output, coord, vec4(result, 1.0));
}
