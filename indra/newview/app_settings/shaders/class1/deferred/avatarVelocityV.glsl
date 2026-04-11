/**
 * @file avatarVelocityV.glsl
 *
 * MARE: vertex shader for the skinned (rigged mesh) velocity pass (Phase 2 Step 4).
 *
 * Applies GPU skinning to each vertex using BOTH the current-frame bone palette
 * (matrixPalette, already computed by the GBuffer pass) and the previous-frame
 * bone palette (prevMatrixPalette, snapshot in updateSkinInfoMatrixPalette()).
 *
 * Weight / index encoding follows the SL objectSkinV.glsl convention:
 *   floor(weight4) = bone indices (0..MAX_JOINTS_PER_MESH_OBJECT-1)
 *   fract(weight4) = un-normalised blend weights (normalised here)
 *
 * Both resulting world-space positions are projected to clip space and passed
 * to the fragment shader as varyings so it can output the NDC velocity delta.
 *
 * Depth test (GL_LEQUAL, no writes) in the dispatch ensures only visible pixels
 * of each skinned face overwrite the camera-reprojection velocity.
 *
 * Phase 2 Step 4 — skinned / avatar motion vectors for TAA / FSR 2 upscaler.
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

in vec3 position;   // object-space vertex position (bind pose)
in vec4 weight4;    // bone blend weights & indices (SL convention)

// Current-frame bone palette: uploaded via AVATAR_MATRIX each frame by the GBuffer pass.
uniform mat3x4 matrixPalette[MAX_JOINTS_PER_MESH_OBJECT];

// Previous-frame bone palette: snapshotted from mPrevGLMp in the skinned velocity dispatch.
uniform mat3x4 prevMatrixPalette[MAX_JOINTS_PER_MESH_OBJECT];

uniform mat4 modelview_matrix;   // auto-uploaded: camera view (no model; bones include world)
uniform mat4 projection_matrix;  // auto-uploaded: current projection
uniform mat4 prev_vp;            // MARE: previous-frame proj * view (set per-draw call)

out vec4 vary_curr_clip;
out vec4 vary_prev_clip;

void main()
{
    // --- Decode weight4 into normalised weights and clamped bone indices ---
    vec4 w     = fract(weight4);
    vec4 idx_f = floor(weight4);
    idx_f = clamp(idx_f, vec4(0.0), vec4(MAX_JOINTS_PER_MESH_OBJECT - 1));
    w    /= max(w.x + w.y + w.z + w.w, 0.001);

    int i1 = int(idx_f.x);
    int i2 = int(idx_f.y);
    int i3 = int(idx_f.z);
    int i4 = int(idx_f.w);

    // --- Current-frame skinning (matrixPalette) ---
    mat3 rot_c =  mat3(matrixPalette[i1]) * w.x
               +  mat3(matrixPalette[i2]) * w.y
               +  mat3(matrixPalette[i3]) * w.z
               +  mat3(matrixPalette[i4]) * w.w;

    vec3 trs_c =  vec3(matrixPalette[i1][0].w, matrixPalette[i1][1].w, matrixPalette[i1][2].w) * w.x
               +  vec3(matrixPalette[i2][0].w, matrixPalette[i2][1].w, matrixPalette[i2][2].w) * w.y
               +  vec3(matrixPalette[i3][0].w, matrixPalette[i3][1].w, matrixPalette[i3][2].w) * w.z
               +  vec3(matrixPalette[i4][0].w, matrixPalette[i4][1].w, matrixPalette[i4][2].w) * w.w;

    vec3 curr_world = rot_c * position + trs_c;

    // --- Previous-frame skinning (prevMatrixPalette) ---
    mat3 rot_p =  mat3(prevMatrixPalette[i1]) * w.x
               +  mat3(prevMatrixPalette[i2]) * w.y
               +  mat3(prevMatrixPalette[i3]) * w.z
               +  mat3(prevMatrixPalette[i4]) * w.w;

    vec3 trs_p =  vec3(prevMatrixPalette[i1][0].w, prevMatrixPalette[i1][1].w, prevMatrixPalette[i1][2].w) * w.x
               +  vec3(prevMatrixPalette[i2][0].w, prevMatrixPalette[i2][1].w, prevMatrixPalette[i2][2].w) * w.y
               +  vec3(prevMatrixPalette[i3][0].w, prevMatrixPalette[i3][1].w, prevMatrixPalette[i3][2].w) * w.z
               +  vec3(prevMatrixPalette[i4][0].w, prevMatrixPalette[i4][1].w, prevMatrixPalette[i4][2].w) * w.w;

    vec3 prev_world = rot_p * position + trs_p;

    // --- Project both world positions to clip space ---
    vary_curr_clip = projection_matrix * (modelview_matrix * vec4(curr_world, 1.0));
    gl_Position    = vary_curr_clip;

    // prev_vp = prev_proj * prev_view (camera only; bone matrices already include world transform)
    vary_prev_clip = prev_vp * vec4(prev_world, 1.0);

#ifdef IS_AMD_CARD
    // Force static references to prevent AMD driver from optimising away the arrays.
    mat3x4 _d1 = matrixPalette[0];
    mat3x4 _d2 = matrixPalette[MAX_JOINTS_PER_MESH_OBJECT - 1];
    mat3x4 _d3 = prevMatrixPalette[0];
    mat3x4 _d4 = prevMatrixPalette[MAX_JOINTS_PER_MESH_OBJECT - 1];
#endif
}
