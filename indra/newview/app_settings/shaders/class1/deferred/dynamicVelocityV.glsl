/**
 * @file dynamicVelocityV.glsl
 *
 * MARE: vertex shader for the per-object dynamic velocity pass (Phase 2 Step 3).
 *
 * Transforms each vertex by BOTH the current-frame MVP (to set gl_Position) and
 * the previous-frame MVP (prev_mvp, pre-multiplied on the CPU as
 * getPrevViewProj() * mPrevRenderMatrix).  Both clip-space positions are passed
 * as varyings so the fragment shader can output the NDC velocity delta.
 *
 * Called once per face of each drawable that moved this frame.
 * The modelview matrix is set up by gGL.multMatrix(drawable->getRenderMatrix())
 * before the draw call; gGLModelView therefore already equals view * model when
 * LLRender::syncMatrices() uploads it as 'modelview_matrix'.
 *
 * $LicenseInfo:firstyear=2024&license=viewerlgpl$
 * MARE Viewer Source Code
 * $/LicenseInfo$
 */

uniform mat4 modelview_matrix;    // auto-uploaded: current view * model
uniform mat4 projection_matrix;   // auto-uploaded: current projection
uniform mat4 prev_mvp;            // MARE: previous-frame proj * view * model (set per-drawable)

in vec3 position;                 // object-space vertex position

out vec4 vary_curr_clip;          // current-frame clip position
out vec4 vary_prev_clip;          // previous-frame clip position

void main()
{
    vec4 local_pos = vec4(position, 1.0);

    vary_curr_clip = projection_matrix * (modelview_matrix * local_pos);
    gl_Position    = vary_curr_clip;

    vary_prev_clip = prev_mvp * local_pos;
}
